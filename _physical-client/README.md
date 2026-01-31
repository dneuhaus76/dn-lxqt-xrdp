## Create a physical client like the VDI 
Creates a tar.gz Image of the applications, you only apply it by apply Script (partitioning, apply files and execute scripts). The base image contains many drivers (similar the debian live CD) 
- createBaseImage.sh

## Apply
Boot from a live cd, USB, pxe netboot (you could integrate a extract the tar.gz image in this installer, too)
- applyImage.sh

### Apply Archiv - files
- bookworm-amd64.tar.gz   #dynamic ARCH-Name by createBaseImage
- lxqtdebian.tar.gz       #(optional) some settings
- Spin SP111-31.tar.gz    #(optional) Hardware machine based settings

*In this example you should apply the lxqtdebian (Software and Packages are configured to match)*
