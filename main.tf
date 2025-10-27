terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Variables
variable "timestamp" {
  description = "Timestamp to trigger resource recreation"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "script_path" {
  description = "Path to script to execute"
  type        = string
  default     = ""
}

variable "commands" {
  description = "List of commands to execute"
  type        = list(string)
  default     = ["echo 'Hello from Terraform'"]
}

# Null resource with local-exec provisioner
resource "null_resource" "local_exec_example" {
  triggers = {
    always_run = timestamp()
    environment = var.environment
  }

  provisioner "local-exec" {
    command = "echo 'Running local command for ${var.environment} environment'"
  }

  provisioner "local-exec" {
    command = join(" && ", var.commands)
  }
}

# Null resource that runs on specific changes
resource "null_resource" "conditional_trigger" {
  triggers = {
    timestamp = var.timestamp
  }

  provisioner "local-exec" {
    command = "echo 'Triggered at: ${var.timestamp}'"
  }
}

# Null resource with script execution
resource "null_resource" "script_runner" {
  count = var.script_path != "" ? 1 : 0

  triggers = {
    script_hash = filemd5(var.script_path)
  }

  provisioner "local-exec" {
    command = "bash ${var.script_path}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Cleanup: Resource is being destroyed'"
  }
}

# Null resource with dependencies
resource "null_resource" "depends_on_example" {
  depends_on = [null_resource.local_exec_example]

  provisioner "local-exec" {
    command = "echo 'This runs after local_exec_example completes'"
  }
}

# Null resource with working directory
resource "null_resource" "with_working_dir" {
  provisioner "local-exec" {
    command     = "pwd && ls -la"
    working_dir = path.module
  }
}

# Null resource with environment variables
resource "null_resource" "with_env_vars" {
  provisioner "local-exec" {
    command = "echo Environment: $ENV_NAME, Region: $REGION"
    environment = {
      ENV_NAME = var.environment
      REGION   = "us-east-1"
    }
  }
}

# Outputs
output "execution_id" {
  description = "ID of the main null resource"
  value       = null_resource.local_exec_example.id
}

output "trigger_timestamp" {
  description = "Timestamp that triggered execution"
  value       = null_resource.local_exec_example.triggers.always_run
}

output "script_runner_ids" {
  description = "IDs of script runner resources"
  value       = null_resource.script_runner[*].id
}
