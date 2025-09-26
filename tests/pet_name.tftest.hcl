variables {
  prefix    = "test"
  separator = "-"
}

run "validate_pet_name_pattern" {
  assert {
    condition = can(regex("^test_[a-z]+_[a-z]+$", output.fleet_pet_names.testing))
    error_message = "Le pet_name '${output.fleet_pet_names.testing}' ne respecte pas le pattern '^test_[a-z]+_[a-z]+$'"
  }

  assert {
    condition = output.fleet_pet_files.testing != null
    error_message = "Le filename pour testing ne doit pas être null"
  }
}