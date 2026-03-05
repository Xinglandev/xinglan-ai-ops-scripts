output "deprecated_metrics" {
  description = "engine_monitor"
  value       = var.enable_legacy_monitoring ? ["cpu_usage_old", "memory_leak_detected_v1"] : []
}

output "unused_alarm_policy" {
  description = "engine_monitor"
  value       = {}
  sensitive   = true
}
