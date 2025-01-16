resource "aws_glue_crawler" "glue_crawler" {
  count = length(var.database_names)

  name          = "${local.prefix}-${var.database_names[count.index]}_crawler"
  database_name = var.database_names[count.index]
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = var.bucket_paths[count.index]
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
  })

  #schedule = "cron(15 12 * * ? *)"

  tags = merge(
    local.common_tags,
  )
}
