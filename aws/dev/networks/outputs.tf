output "vpc_id"                 { 
    value = aws_vpc.this.id 
}
output "public_subnet_ids"      { 
    value = [for s in aws_subnet.public : s.id] 
}
output "private_app_subnet_ids" { 
    value = [for s in aws_subnet.app : s.id] 
    }
output "private_db_subnet_ids"  { 
    value = [for s in aws_subnet.db : s.id] 
    }
output "db_subnet_group_name"   { 
    value = aws_db_subnet_group.db.name 
}
