cd ~
mv Documents documents
mv Desktop desktop
mv Downloads downloads
mv Music music
mv Pictures pictures
mv Public public
mv Templates templates
mv Videos videos
xdg-user-dirs-update --set DOCUMENTS ~/documents
xdg-user-dirs-update --set DESKTOP ~/desktop
xdg-user-dirs-update --set DOWNLOAD ~/downloads
xdg-user-dirs-update --set MUSIC ~/music
xdg-user-dirs-update --set PICTURES ~/pictures
xdg-user-dirs-update --set PUBLICSHARE ~/public
xdg-user-dirs-update --set TEMPLATES ~/templates
xdg-user-dirs-update --set VIDEOS ~/videos

mkdir projects
mkdir projects/go
mkdir projects/go/src
mkdir projects/go/pkg
mkdir projects/go/bin
mkdir projects/python
mkdir projects/node
mkdir projects/rust
mkdir projects/sites
