resource "aws_route53_zone" "daan-se" {
  name = "daan.se"
  tags = local.default-tags
}

variable "street" {
  type = string
}
variable "city" {
  type = string
}
variable "zip_code" {
  type = string
}
variable "phone_number" {
  type = string
}
variable "rijksregister_nummer" {
  type = string
}

resource "aws_route53domains_domain" "daan-se" {
  domain_name = "daan.se"
  auto_renew  = true

  registrant_privacy = true
  transfer_lock = false
  # duration_in_years = null

  admin_contact {
    address_line_1    = var.street
    city              = var.city
    contact_type      = "PERSON"
    country_code      = "BE"
    email             = "daanwendelen@gmail.com"
    first_name        = "Daan"
    last_name         = "Wendelen"
    phone_number      = var.phone_number
    zip_code          = var.zip_code
    extra_param {
      name  = "SE_ID_NUMBER"
      value = var.rijksregister_nummer
    }
  }

  registrant_contact {
    address_line_1    = var.street
    city              = var.city
    contact_type      = "PERSON"
    country_code      = "BE"
    email             = "daanwendelen@gmail.com"
    extra_param {
      name = "BIRTH_COUNTRY"
      value = "BE"
    }
    extra_param {
      name  = "SE_ID_NUMBER"
      value = "[BE]${var.rijksregister_nummer}"
    }
    first_name        = "Daan"
    last_name         = "Wendelen"
    phone_number      = var.phone_number
    zip_code          = var.zip_code
  }

  tech_contact {
    address_line_1    = var.street
    city              = var.city
    contact_type      = "PERSON"
    country_code      = "BE"
    email             = "daanwendelen@gmail.com"
    first_name        = "Daan"
    last_name         = "Wendelen"
    phone_number      = var.phone_number
    zip_code          = var.zip_code
    extra_param {
      name  = "SE_ID_NUMBER"
      value = var.rijksregister_nummer
    }
  }

  tags = local.default-tags
}