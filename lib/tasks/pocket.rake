namespace 'pocket' do
  desc 'send mail'
  task 'send_mail' => :environment do
    User.all.each do |user|
      p "user: #{user.name}"
      client = Pocket.client(access_token: user.oauth_token)
      result = client.retrieve(count: 50)
      next unless result['status'] == 1

      result['list'].values.sample(5).each do |item|
        p item['given_title']
      end
    end
  end
end
