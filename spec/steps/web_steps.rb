step 'I visit :name page' do |name|
  page.driver.browser.authorize 'best10admin', 'best10admin2014'

  if name == 'top'
    url = '/'
  else
    url = name
  end

  visit url
end

step 'It should succeed' do
  expect(page.status_code).to eq(200)
end

step 'I should see :text' do |text|
  expect(page).to have_content(text)
end

step 'I should see link for :href' do |href|
  expect(page).to have_link(href: href)
end
