/*
resource "aws_db_instance" "mysql" {
    identifier_prefix = "dev-mysql"
    engine = "mysql"
    engine_version = "8.0.36"
    instance_class = "db.t3.micro"
    allocated_storage = 20
    storage_type = "gp3"



    db_name = var.db_name
    username = var.db_username
    password = var.db_password

  
}
*/