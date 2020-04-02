resource "aws_cloudwatch_metric_alarm" "autoscale_medium_workers" {
  alarm_name                = "${var.prefix}-autoscale-medium-workers"
  alarm_description         = "Autoscale medium-workers based on RabbitMQ medium queue depth on ${var.common_tags["env"]}"
  namespace                 = "${var.common_tags["env"]}.rabbitmq.depth"
  metric_name               = "medium"
  comparison_operator       = "GreaterThanThreshold"
  threshold                 = "0"
  period                    = "10"
  evaluation_periods        = "1"
  statistic                 = "Average"
  insufficient_data_actions = []

  alarm_actions = [aws_appautoscaling_policy.medium_worker_scale_up.arn]
  ok_actions    = [aws_appautoscaling_policy.medium_worker_scale_down.arn]
}

resource "aws_appautoscaling_target" "medium_worker_autoscaling_target" {
  min_capacity       = var.medium_worker["minimum_count"]
  max_capacity       = var.medium_worker["maximum_count"]
  resource_id        = "service/${var.ecs_cluster["name"]}/${aws_ecs_service.worker.name}"
  role_arn           = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/ecs.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_ECSService"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "medium_worker_scale_up" {
  name               = "medium-worker-scale-up"
  policy_type        = "StepScaling"
  resource_id        = "service/${var.ecs_cluster["name"]}/${aws_ecs_service.worker.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ExactCapacity"
    cooldown                = 15
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      metric_interval_upper_bound = 30
      scaling_adjustment          = var.medium_worker["desired_count_scale_step_1"]
    }

    step_adjustment {
      metric_interval_lower_bound = 30
      metric_interval_upper_bound = 50
      scaling_adjustment          = var.medium_worker["desired_count_scale_step_2"]
    }

    step_adjustment {
      metric_interval_lower_bound = 50
      metric_interval_upper_bound = 100
      scaling_adjustment          = var.medium_worker["desired_count_scale_step_3"]
    }

    step_adjustment {
      metric_interval_lower_bound = 100
      scaling_adjustment          = var.medium_worker["maximum_count"]
    }
  }

  depends_on = [aws_appautoscaling_target.medium_worker_autoscaling_target]
}

resource "aws_appautoscaling_policy" "medium_worker_scale_down" {
  name               = "medium-worker-scale-down"
  policy_type        = "StepScaling"
  resource_id        = "service/${var.ecs_cluster["name"]}/${aws_ecs_service.worker.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ExactCapacity"
    cooldown                = 15
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = var.medium_worker["minimum_count"]
    }
  }

  depends_on = [aws_appautoscaling_target.medium_worker_autoscaling_target]
}

