variables {
  prefix    = "test"
  separator = "-"
}

run "validate_pet_name_pattern" {
  assert {
    condition = can(regex("^test-[a-z]+-[a-z]+$", output.pet_name))
    error_message = "Le pet_name '${output.pet_name}' ne respecte pas le pattern '^test-[a-z]+-[a-z]+$'"
  }

  assert {
    condition = output.filename != null
    error_message = "Le filename ne doit pas être null"
  }
}