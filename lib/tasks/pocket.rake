# -*- coding: utf-8 -*-
require 'mandrill'

namespace 'pocket' do
  desc 'send mail'
  task 'send_mail' => :environment do
    User.all.each do |user|
      p "user: #{user.name}"
      next unless user.email
      p "email: #{user.email}"

      client = Pocket.client(access_token: user.oauth_token)
      result = client.retrieve(count: 50)
      next unless result['status'] == 1

      html = ''
      result['list'].values.sample(5).each do |item|
        p item['given_title']
      end

      begin
        mandrill = Mandrill::API.new ENV['MANDRILL_API_KEY']
        params = {
          recipient_metadata: [{ rcpt: user.email, values: { username: user.name } }],
          global_merge_vars: [{ content: 'merge1 content', name: 'merge1' }],
          track_opens: true,
          merge_language: 'mailchimp',
          merge: true,
          from_email: 'pocketpop@kumonos.jp',
          from_name: 'Pocket Pop',
          subject: 'Pocket未読記事: 今日の5件',
          view_content_link: nil,
          track_clicks: nil,
          to: [{ email: user.email,
                 type: 'to',
                 name: user.name }],
          html: html,
          tags: ['pocket pop daily'],
          headers: { 'Reply-To' => 'info@kumonos.jp' }
        }
        async = false
        result = mandrill.messages.send params, async
        p result
      rescue Mandrill::Error => e
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      end
    end
  end
end
