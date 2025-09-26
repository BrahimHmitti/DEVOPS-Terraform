output "pet_name" {
  value = random_pet.pet.id
}

output "filename" {
  value = local_file.pet_file.filename
}
 

output "number" {
  value = random_integer.number.result
}

#output "password" {
#  value = random_password.password.result
#"}