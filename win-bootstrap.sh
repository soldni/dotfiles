ln -s `pwd`/.vimrc $HOME/.vimrc
ln -s `pwd`/.gvimrc $HOME/.gvimrc
ln -s `pwd`/.vim $HOME/.vim

git update-index --assume-unchanged .prelocalrc
git update-index --assume-unchanged .postlocalrc
