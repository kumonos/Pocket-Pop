# -*- coding: utf-8 -*-
require 'mandrill'
require 'render_anywhere'

namespace 'pocket' do
  desc 'send mail'
  task 'send_mail' => :environment do
    include RenderAnywhere

    # workaround for RenderAnywhere
    String.class_eval { undef_method :render }

    MAX_COUNT = 10
    BASE_URL = 'http://pocketporter.kumonos.jp/'
    mandrill = Mandrill::API.new ENV['MANDRILL_API_KEY']
    today = Time.now.strftime('%Y年%m月%d日')

    User.all.each do |user|
      p "user: #{user.name}"
      next unless user.email
      p "email: #{user.email}"

      client = Pocket.client(access_token: user.oauth_token)
      result = client.retrieve(count: 50, detailType: 'complete')
      next unless result['status'] == 1

      items = []
      result['list'].values.sample(MAX_COUNT).each do |item|
        item_url = item['resolved_url'] || item['given_url']
        next unless item_url

        redirect_url = "#{BASE_URL}archive?id=#{item['item_id']}&url=#{item_url}"

        items << {
          title: item['resolved_title'] || item['given_title'] || item_url,
          image: item['images'] && item['images']['1'] && item['images']['1']['src'],
          url: redirect_url,
          excerpt: item['excerpt'] || ''
        }
      end
      next if items.empty?

      begin
        html = render template: 'mailer/pocket', layout: nil, locals: { items: items }
        puts html
        params = {
          recipient_metadata: [{ rcpt: user.email, values: { username: user.name } }],
          global_merge_vars: [{ content: 'merge1 content', name: 'merge1' }],
          track_opens: true,
          merge_language: 'mailchimp',
          merge: true,
          from_email: 'pocketporter@kumonos.jp',
          from_name: 'Pocket Porter',
          subject: "#{today}のPocket未読記事#{items.count}件",
          view_content_link: nil,
          track_clicks: nil,
          to: [{ email: user.email,
                 type: 'to',
                 name: user.name }],
          html: html,
          tags: ['pocket porter daily'],
          headers: { 'Reply-To' => 'info@kumonos.jp' }
        }
        async = false
        result = mandrill.messages.send params, async
        puts result
      rescue Mandrill::Error => e
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      end
    end
  end
end
