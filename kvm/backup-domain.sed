# starting whitespace
s/      //

# source file (not pool) disks
s/<source file='//

# default pool
s/<source pool='default'/\/var\/lib\/libvirt\/images\//

# images pool
s/<source pool='images'/\/mnt\/data\/images\//

# iso pool
s/<source pool='iso'/\/var\/lib\/libvirt\/iso\//

# volume
s/ volume='//

# disk index
s/' index='[0-9]*'\/>//

# closing xml tag
s/'\/>//