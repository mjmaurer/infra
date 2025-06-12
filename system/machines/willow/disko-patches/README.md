For expanding NAS, probably want to create a separate mirrored vdev and add it to the NAS pool. RAIDz (vdev) expanding launched recently, but it has some downsides (I think it inherits the existing vdev's parity). Plus, a bunch of mirrored vdevs would allow for dedicating lower performing disks to less-accessed NAS paths (via a separate pool if needed).

Consider also: https://jrs-s.net/2015/02/06/zfs-you-should-use-mirror-vdevs-not-raidz/
I'm a bit skeptical, because the above argument about lower performing disks could apply just as well to raidz as mirrored

