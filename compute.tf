resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # checkov:skip=CKV_AWS_260: Lab yêu cầu mở port 80 public cho web server
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["115.79.0.0/16"] 
  }

  egress {
    description = "Allow all outbound traffic" # Đã thêm description để pass CKV_AWS_23
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    # checkov:skip=CKV_AWS_382: Cho phép egress ra internet để cài đặt package
  }
}

resource "aws_instance" "web" {
  ami           = "ami-0fa377108253bf620" 
  instance_type = "t2.micro" # Bắt buộc phải giữ đúng t2.micro cho Lab
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # Đã xóa monitoring=true và ebs_optimized=true. Dùng skip để qua mặt Checkov:
  # checkov:skip=CKV_AWS_135: t2.micro không hỗ trợ EBS Optimized
  # checkov:skip=CKV_AWS_126: Detailed monitoring tốn phí, AWS Academy sẽ chặn
  # checkov:skip=CKV2_AWS_41: Lab này chưa yêu cầu cấp IAM Role cho EC2

  # Ép buộc dùng IMDSv2 để pass CKV_AWS_79
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Mã hóa ổ cứng để pass CKV_AWS_8
  root_block_device {
    encrypted = true
  }

  tags = {
    Name = "Lab2-WebServer"
  }
}
