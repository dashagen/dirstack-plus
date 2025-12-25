# This script uses dt, a script to show direcotry stack
# in a tree layout

###################################
##  Define Functions  #############
###################################
function updatedirs()
{

    IFS=$'\r\n'

    dirlist=( `cat $DIRSFILE|cut -c5-` )

    for i in `seq 0 $((${#dirlist[@]}-1))`;do
        export dir$i="${dirlist[$i]}"
    done
}


# Set the title of an xterm to $PWD
function xtitle()
{
    echo -ne "\033]0;[P$prj_num][$PRJN]-[T$CUR_TTY]:$(basename "$(pwd)")\a"
}


# Change project name
function chgprj()
{
    if [ $1 ]; then
        PRJN=$1
        echo $PRJN >| $HOME/.dirstack/prjname$prj_num
    fi
    xtitle
}

# Clear current dirstack file
function cstack()
{
    DY_NS=`wc -l $DIRSFILE|awk '{print $1}'`

    for i in `seq 2 $DY_NS`
    do
        popd >/dev/null
    done

    cd $HOME

    sd
}


# Load dirs from a dirstack file
function lstack()
{
    DY_NS=`wc -l $DIRSFILE|awk '{print $1}'`

    for i in `seq 2 $DY_NS`
    do
        popd >/dev/null
    done

    for i in `sort -k1nr $1 | cut -c5- `;do
        pushd $i >/dev/null
    done

    sd
}



# List directories in the current stack
function sd()
{
    dirs -v -l >| $DIRSFILE
    dt
    updatedirs
    xtitle
}


# Re-engineered CD that will modify the dirstack each time
function cd()
{
    if [ "$1" ]; then
        p_dir=`realpath $1`
        dirlist=( `cat $DIRSFILE|cut -c5-` )

        match_idx=-1
        #check if dir already in the stack
        for i in `seq 0 $((${#dirlist[@]}-1))`; do
            chk_path=`realpath ${dirlist[$i]}`

            if [ "$chk_path" = "$p_dir" ]; then
                match_idx=$i
            fi
        done

        if [ "$match_idx" = "-1" ]; then
            builtin cd "$@"
            dirs -v -l >| $DIRSFILE
            xtitle
        else
            r $match_idx
        fi
    fi
}



# Rotate the dirstack
function r()
{
    if [ -z "$1" ];then
        pushd >/dev/null
    else
        if [[ "$1" -gt 0 ]]; then
            for (( i=2;i<=$1;i++ ));do
                pushd >/dev/null
                pushd +1 >/dev/null
            done
            pushd >/dev/null
        fi
    fi

    ls -G -ltr
    echo
    sd
}



# Go to dirstack by keyword
function g()
{
    if [ $1 ]; then
        PICKNUM=`grep -i $1 $DIRSFILE|head -1|awk '{print $1}'`
        r $PICKNUM
    else
        echo "missing searchword"
    fi
}


# Push into dirstack
function pu()
{
    if [ "$1" ]; then
        p_dir=`realpath $1`

        dirlist=( `cat $DIRSFILE|cut -c5-` )

        match_idx=-1

        #check if dir already in the stack
        for i in `seq 0 $((${#dirlist[@]}-1))`; do
            chk_path=`realpath ${dirlist[$i]}`

            if [ "$chk_path" = "$p_dir" ]; then
                match_idx=$i
            fi
        done

        if [ "$match_idx" = "-1" ]; then
            pushd "$1" >/dev/null
            sd
        else
            r $match_idx
        fi
    else
        pushd +1 >/dev/null
        sd
    fi
}



# Pop out of dirstack
function po()
{
    if [ $1 ]
    then
        popd "+$1" >/dev/null
    else
        popd +0 >/dev/null
    fi

    sd
}


# Show dirs in dirstack in order
sdd ()
{
    echo;
    echo "/-------------------------------------------------------------------";

    sort -k2 $DIRSFILE |
        awk '{
            if (NR%2==1)
            { print "\033[0;33m"$0"\033[0m"}

            else
            { print "\033[0;32m"$0"\033[0m"}

        }';
    echo "\-------------------------------------------------------------------"
}


# Remove branch from the parent
db ()
{
    if [ $1 ]; then
        pdir=$(dirname $(eval "echo \$dir$1"))

        for dn in `grep $pdir $DIRSFILE|awk '{print $1}'|sort -k1nr`; do
            popd +$dn > /dev/null
        done;

        sd
    else
        echo "Specifiy a directory number"
    fi
}


###################################
##  Initialization      ###########
###################################

IFS=$'\r\n'

# Get current Project Number
export prj_num=$(getprjnum)

# Update Project Name and dirstack
export PRJN=$(cat $HOME/.dirstack/prjname$prj_num)
export DIRSFILE="$HOME/.dirstack/dirstack$prj_num"
export CUR_TTY=$(tty|sed -e 's/[^0-9]//g')

# Load dirstack and Initialize dir# variables
dirlist=( `sort -k1nr $HOME/.dirstack/dirstack$prj_num|cut -c5-` )

for i in `seq 0 $((${#dirlist[@]}-1))`;do

    export dir$i="${dirlist[$i]}"

    pushd "${dirlist[$i]}" >/dev/null
done

popd -0 >/dev/null

echo
echo "Previously..."
dirs -v -l
echo

xtitle

