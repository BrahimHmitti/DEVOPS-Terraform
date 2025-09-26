variables {
  prefix    = ""
  separator = "-"
}

run "test_empty_prefix_should_fail" {
  command = plan
  expect_failures = [
    var.prefix,
  ]
}

run "test_invalid_separator_should_fail" {
  command = plan
  
  variables {
    prefix    = "test"
    separator = "|"
  }
  
  expect_failures = [
    var.separator,
  ]
}

run "test_valid_config_should_pass" {
  command = apply

  variables {
    prefix    = "prod"
    separator = "_"
  }

  assert {
    condition = can(regex("^prod-[a-z]+-[a-z]+$", output.fleet_pet_names.production))
    error_message = "Pattern invalide pour prod-: ${output.fleet_pet_names.production}"
  }
}
