# ============================================================================
# Terraform Null Resource Examples Module
# A comprehensive module demonstrating various null_resource patterns
# ============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# ============================================================================
# VARIABLES
# ============================================================================

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Command Executor Variables
variable "enable_command_executor" {
  description = "Enable command executor pattern"
  type        = bool
  default     = true
}

variable "commands" {
  description = "List of commands to execute"
  type        = list(string)
  default     = ["echo 'Hello from Terraform'"]
}

variable "working_dir" {
  description = "Working directory for command execution"
  type        = string
  default     = ""
}

variable "env_vars" {
  description = "Environment variables for command execution"
  type        = map(string)
  default     = {}
}

# Script Runner Variables
variable "enable_script_runner" {
  description = "Enable script runner pattern"
  type        = bool
  default     = false
}

variable "script_path" {
  description = "Path to script file to execute"
  type        = string
  default     = ""
}

variable "script_args" {
  description = "Arguments to pass to the script"
  type        = string
  default     = ""
}

# Trigger Variables
variable "enable_always_run" {
  description = "Enable always-run trigger (runs on every apply)"
  type        = bool
  default     = false
}

variable "trigger_on_change" {
  description = "Value that triggers re-execution when changed"
  type        = string
  default     = ""
}

# Destroy Provisioner Variables
variable "enable_destroy_provisioner" {
  description = "Enable destroy-time provisioner"
  type        = bool
  default     = false
}

variable "destroy_commands" {
  description = "Commands to run on resource destruction"
  type        = list(string)
  default     = ["echo 'Cleaning up...'"]
}

# ============================================================================
# NULL RESOURCES
# ============================================================================

# Pattern 1: Command Executor with Environment Variables
resource "null_resource" "command_executor" {
  count = var.enable_command_executor ? 1 : 0

  triggers = merge(
    {
      environment = var.environment
      commands    = join(",", var.commands)
    },
    var.enable_always_run ? { always_run = timestamp() } : {},
    var.trigger_on_change != "" ? { trigger = var.trigger_on_change } : {}
  )

  provisioner "local-exec" {
    command     = join(" && ", var.commands)
    working_dir = var.working_dir != "" ? var.working_dir : null
    environment = merge(
      { ENVIRONMENT = var.environment },
      var.env_vars
    )
  }
}

# Pattern 2: Script Runner with File Hash Trigger
resource "null_resource" "script_runner" {
  count = var.enable_script_runner && var.script_path != "" ? 1 : 0

  triggers = {
    script_hash = fileexists(var.script_path) ? filemd5(var.script_path) : ""
    script_args = var.script_args
  }

  provisioner "local-exec" {
    command = "${var.script_path} ${var.script_args}"
  }
}

# Pattern 3: Destroy-Time Provisioner
resource "null_resource" "destroy_provisioner" {
  count = var.enable_destroy_provisioner ? 1 : 0

  triggers = {
    environment      = var.environment
    destroy_commands = join(" && ", var.destroy_commands)
  }

  provisioner "local-exec" {
    when    = destroy
    command = self.triggers.destroy_commands
  }
}

# Pattern 4: Dependency Orchestrator
resource "null_resource" "orchestrator" {
  depends_on = [
    null_resource.command_executor,
    null_resource.script_runner
  ]

  triggers = {
    timestamp = var.enable_always_run ? timestamp() : ""
  }

  provisioner "local-exec" {
    command = "echo 'All dependent resources completed for ${var.environment}'"
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "command_executor_id" {
  description = "ID of the command executor resource"
  value       = var.enable_command_executor ? null_resource.command_executor[0].id : null
}

output "script_runner_id" {
  description = "ID of the script runner resource"
  value       = var.enable_script_runner && var.script_path != "" ? null_resource.script_runner[0].id : null
}

output "destroy_provisioner_id" {
  description = "ID of the destroy provisioner resource"
  value       = var.enable_destroy_provisioner ? null_resource.destroy_provisioner[0].id : null
}

output "orchestrator_id" {
  description = "ID of the orchestrator resource"
  value       = null_resource.orchestrator.id
}

output "execution_summary" {
  description = "Summary of module execution"
  value = {
    environment              = var.environment
    command_executor_enabled = var.enable_command_executor
    script_runner_enabled    = var.enable_script_runner && var.script_path != ""
    destroy_provisioner_enabled = var.enable_destroy_provisioner
    always_run_enabled       = var.enable_always_run
    timestamp                = timestamp()
  }
}
