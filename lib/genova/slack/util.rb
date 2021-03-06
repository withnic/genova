module Genova
  module Slack
    class Util
      class << self
        def history_options(slack_user_id)
          options = []

          histories = Genova::Slack::History.new(slack_user_id).list
          histories.each do |history|
            history = Oj.load(history)
            options.push(
              text: history[:id],
              value: history[:id],
              description: "#{history[:repository]} (#{history[:branch]})"
            )
          end

          options
        end

        def repository_options
          options = []

          repositories = Settings.github.repositories.map { |h| h[:name] } || []
          repositories.each do |repository|
            options.push(text: repository, value: repository)
          end

          options
        end

        def branch_options(account, repository, branch_limit = Settings.slack.interactive.branch_limit)
          repository_manager = Genova::Git::RepositoryManager.new(account, repository)
          branches = []
          size = 0

          repository_manager.origin_branches.each do |branch|
            break if size >= branch_limit

            size += 1
            branches.push(text: branch.name, value: branch.name)
          end

          branches
        end

        def cluster_options(account, repository, branch)
          clusters = []
          repository_manager = Genova::Git::RepositoryManager.new(account, repository, branch)

          deploy_config = repository_manager.load_deploy_config
          deploy_config[:clusters].each do |cluster_params|
            clusters.push(text: cluster_params[:name], value: cluster_params[:name])
          end

          clusters
        end

        def target_options(account, repository, branch, cluster)
          service_options = []
          scheduled_task_options = []

          repository_manager = Genova::Git::RepositoryManager.new(account, repository, branch)
          cluster_config = repository_manager.load_deploy_config.cluster(cluster)

          if cluster_config[:services].present?
            cluster_config[:services].keys.each do |service|
              service_options.push(
                text: service,
                value: "service:#{service}"
              )
            end
          end

          if cluster_config[:scheduled_tasks].present?
            cluster_config[:scheduled_tasks].each do |rule|
              targets = rule[:targets] || {}
              targets.each do |target|
                scheduled_task_options.push(
                  text: "#{rule[:rule]}:#{target[:name]}",
                  value: "scheduled_task:#{rule[:rule]}:#{target[:name]}"
                )
              end
            end
          end

          [
            {
              text: 'Service',
              options: service_options
            },
            {
              text: 'Scheduled task',
              options: scheduled_task_options
            }
          ]
        end
      end
    end
  end
end
