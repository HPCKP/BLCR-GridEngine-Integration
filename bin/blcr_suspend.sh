#!/bin/sh
set +u

#source /etc/profile.d/modules.sh
#module load blcr
export PATH=/aplic/BLCR/0.8.2/bin:$PATH
export LD_LIBRARY_PATH=/aplic/BLCR/0.8.2/lib:$LD_LIBRARY_PATH


ckpt_dir=$SGE_O_WORKDIR
if [ ! -f $ckpt_dir/ckpt.log ]; then
  touch $ckpt_dir/ckpt.log
  chmod 666 $ckpt_dir/ckpt.log
fi
sge_root=${SGE_ROOT}
sge_cell=${SGE_CELL}
# workaround to force job to restart on same queue (svd)
qalter -q $QUEUE $JOB_ID
# create temp directory for holding checkpoint info
tmpdir=$ckpt_dir/ckpt.$1
mkdir -p $tmpdir
cd $tmpdir
# checkpoint the job to one of two different files (i.e. ping-pong)
# just in case we go down while checkpointing
currcpr=`cat currcpr`
if [ "$currcpr" = "2" ]; then
  currcpr=1
  prevcpr=2
else
  currcpr=2
  prevcpr=1
fi
ckptfile=context_$1.$currcpr
pid=$2
# get the child process to checkpoint
echo `pstree -p $pid` >> $ckpt_dir/ckpt.log 2>&1
cpid=`pstree -p $pid | awk -F "(" '{ print $NF }' | awk -F ")" '{ print $1}'`
echo Checkpoint(Suspend) command: cr_checkpoint -f $ckptfile --stop $cpid >> $ckpt_dir/ckpt.log 2>&1 
cr_checkpoint -f $ckptfile --stop $cpid
cc=$?
if [ $cc -eq 0 ]; then
  echo $currcpr > currcpr
  if [ -f context_$1.$prevcpr ]; then
    echo Deleting old checkpoint file >> $ckpt_dir/ckpt.log 2>&1
    rm -f context_$1.$prevcpr
  fi
fi
echo `date +"%D %T"` Job $1 "(pid=$cpid) checkpointed, status=$cc" >> $ckpt_dir/ckpt.log

