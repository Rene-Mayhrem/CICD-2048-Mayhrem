output "alb_dns_name" {
  description = "Public URL of the 2048 Game"
  value = aws_lb.game_alb.dns_name
}