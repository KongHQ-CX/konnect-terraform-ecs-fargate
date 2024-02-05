# Anything that requires external data not managed by this stack, put in here
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}
