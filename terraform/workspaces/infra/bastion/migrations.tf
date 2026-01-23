#
# aws-on-prem -> enterprise
#

# bastion module uses enabled variable
moved {
  from = module.bastion
  to   = module.bastion[0]
}
