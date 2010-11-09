#!/bin/sh

export SGE_CKPT_DIR=$SGE_O_WORKDIR
export tmpdir=${SGE_CKPT_DIR}/ckpt.${JOB_ID}

# Test if restarted/migrated
if [ $RESTARTED = 0 ]; then
   # 0 = not restarted
   # Parts to be executed only during the first
   # start go in here
   /usr/bin/cr_run $*
else
   # Start the checkpointing executable
   currcpr=`cat ${tmpdir}/currcpr`
   ckptfile=${tmpdir}/context_${JOB_ID}.$currcpr
   if [ -f $SGE_CKPT_DIR/pid.log ]; then
      pid=`cat $SGE_CKPT_DIR/pid.log`
      if [ `pstree -p $pid|wc -m` == 0 ]; then
         echo "Restarting from $ckptfile on $HOSTNAME host at" `date +"%D %T"` >> $SGE_CKPT_DIR/ckpt.log
         /usr/bin/cr_restart $ckptfile
      else 
         echo "The system is using this process ID ($pid). Restart failed." >> $SGE_CKPT_DIR/ckpt.log
         #exit 1;
      fi
   else
      echo "Missing the pid file. Restart failed." >> $SGE_CKPT_DIR/ckpt.log
   fi
fi

