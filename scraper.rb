require 'scraperwiki'
require 'rubygems'
require 'mechanize'

comment_url = 'mailto:tareecouncil@gtcc.nsw.gov.au?subject='
starting_url = 'http://icon.gtcc.nsw.gov.au/eplanning/Pages/XC.Track/SearchApplication.aspx?d=lastmonth&k=LodgementDate&t=290'

def clean_whitespace(a)
  a.gsub("\r", ' ').gsub("\t", ' ').squeeze(" ").strip
end

def scrape_page(doc, comment_url)
  doc.search('.result').each do |result|
    info_url = (doc.uri + result.at('a')['href']).to_s
    lines = clean_whitespace(result.inner_text).split("\n")
    lines.map {|line| line.strip!}
    record = {
      'info_url' => info_url,
      'comment_url' => comment_url + CGI::escape("Development Application Enquiry: " + lines[0]),
      'council_reference' => lines[0],
      'date_received' => Date.strptime(lines[3], '%d/%m/%Y').to_s,
      'address' => lines[4].gsub('Address: ', '').gsub(/Applicant.*/, ''),
      'description' => lines[1],
      'date_scraped' => Date.today.to_s
    }
    
    if (ScraperWiki.select("* from data where `council_reference`='#{record['council_reference']}'").empty? rescue true) 
      ScraperWiki.save_sqlite(['council_reference'], record)
    else
      puts "Skipping already saved record " + record['council_reference']
    end
  end
end

agent = Mechanize.new

# Jump through bollocks agree screen
doc = agent.get(starting_url)
doc.forms.first.checkboxes.first.checked = true
doc = doc.forms.first.submit(doc.forms.first.button_with(:value => "I Agree"))
doc = agent.get(starting_url)

scrape_page(doc, comment_url)
