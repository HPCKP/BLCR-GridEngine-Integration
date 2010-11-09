#!/bin/sh
set +u

source /etc/profile.d/modules.sh
module load blcr

ckpt_dir=$SGE_O_WORKDIR

if [ ! -f $ckpt_dir/ckpt.log ]; then
   touch $ckpt_dir/ckpt.log
   chmod 666 $ckpt_dir/ckpt.log
fi

tmpdir=$ckpt_dir/ckpt.$1
rm -Rf $tmpdir $ckpt_dir/pid.log

# workaround for qdel failing to kill restarted jobs
# make sure job is really dead

cpid=`pstree -p $2 | awk -F "(" '{ print $NF }' | awk -F ")" '{ print $1 }'`
kill -9 $cpid >> /dev/null 2>&1
kill -9 $2 >> /dev/null 2>&1

echo `date +"%D %T"` Job $1 "(pid=$2) CKPT directory cleaned up" >> $ckpt_dir/ckpt.log

