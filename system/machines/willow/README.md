See secrets.yaml for some configuration notes

The BMC is set as the primary display (over VGA), not the intel's iGPU. The HDMI / DisplayPort outs should not work. You should be able to use a monitor locally over VGA, or remotely over ikvm / bmc.

I did have to enable the iGPU in the BIOS (`Graphics Config > Integrated GPU`).

[This thread](https://forums.servethehome.com/index.php?threads/supermicro-x13sae-f-w680-motherboard-mini-review.37788/#post-352184) says you should be able to have the iGPU through HDMI while also having the BMC on VGA for ipmi, but I didn't test this, and don't really needed it.
