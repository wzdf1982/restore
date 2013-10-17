function die()
{
    echo "${@}"
    exit 1
}

if [ -z "$1" ];then
  echo 'usage: restore.sh [dropbox path]'
  exit 1
fi

if [ -f "zipline.tar" ];then
  rm -fr /home/action/zipline*
fi
wget $1 || die "Can't get dropbox file"

# Add <strong>.old</strong> to any existing Vim file in the home directory
for i in $HOME/.vim $HOME/.vimrc $HOME/.gvimrc; do
  if [[ ( -e $i ) || ( -h $i ) ]]; then
    echo "${i} has been renamed to ${i}.old"
    mv "${i}" "${i}.old" || die "Could not move ${i} to ${i}.old"
  fi
done

# Clone Janus into .vim
git clone https://github.com/carlhuda/janus.git $HOME/.vim \
  || die "Could not clone the repository to ${HOME}/.vim"

# Run rake inside .vim
cd $HOME/.vim || die "Could not go into the ${HOME}/.vim"
rake || die "Rake failed."

gem install backup
backup generate:model --trigger zipline

tar -xvf zipline.tar


cd zipline/archives
find . -exec tar -xvf {} \;
cp -fr home/action/* ~/
cp -fr home/action/.[a-z]* ~/

cd
rm -fr zipline.tar zipline

echo '0 0 * * * backup perform --trigger zipline' > /tmp/.crontab
crontab -l /tmp/.crontab

