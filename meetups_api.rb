require 'net/http'
require 'json'
require 'time'
require 'optparse'
require 'yaml'

Venue = Struct.new(:name, :link)
Meetup = Struct.new(:event_id, :group, :name, :url, :time, :venue, :notable_attendees)
Attendee = Struct.new(:id, :name)

class MeetupsApi
  TIME = ',1w'

  def initialize(api_key, options={})
    @api_key = api_key
    @blacklist = File.readlines(options[:blacklist] || 'blacklist.txt').map(&:chomp)
    @notable_attendees = YAML.load_file(options[:notable_attendees] || 'users.yml')
    @all = !!options[:all]
    @verbose = !!options[:verbose]

    city = options[:city] || 'sydney'
    category = options[:category] || 34 # tech
    @root_url = "https://api.meetup.com/2/open_events?&sign=true&photo-host=public&city=#{city}&country=au&category=#{category}&page=50&time=#{TIME}&key=#{api_key}&limited_events=true"
  end

  def meetups
    events = query_meetup_for_events(@root_url)
    events.reject! { |m| @blacklist.include? m.group } unless @all

    update_notable_attendees(events, @notable_attendees) if @notable_attendees.any?

    events
  end

  private
  def query_meetup_for_events(root_url)
    meetups = []

    get_paged(root_url) do |res|
      meetups += res['results'].map(&method(:to_meetup))
    end

    meetups
  end

  # get a meetup API collection, walking through the pages as necessary
  def get_paged(url, &block)
    puts "verbose: GET #{url}" if OPTIONS[:verbose]
    response = JSON.parse Net::HTTP.get URI.parse url
    
    block.call(response)

    get_paged(response['meta']['next'], &block) unless response['meta']['next'].empty?
  end

  # convert a Meetup.com result into a hash of the bits we use
  def to_meetup(result)
    venue = if result['venue']
      slug = result['venue']['address_1'] + ', ' + result['venue']['city'] + ', Australia'
      Venue.new(result['venue']['name'], "https://maps.google.com/?q=#{URI.encode slug}")
    end

    Meetup.new(result['id'], result['group']['name'], result['name'], result['event_url'], Time.at(result['time'] / 1000).localtime, venue, 0)
  end

  # update the meetup with the "notable" attendees, aka ThoughtWorkers
  def update_notable_attendees(events, users)
    all_rsvps = get_rsvp_yesses events.map(&:event_id)

    events.each do |m|
      rsvps = all_rsvps[m.event_id] || []
      m.notable_attendees = rsvps.select { |r| users.include? r.id }
      puts "verbose: #{m.event_id} has #{rsvps.count} attendees (#{m.notable_attendees} notable)" if @verbose
    end
  end

  # get a list of all RSVPs who've said Yes
  def get_rsvp_yesses(event_ids)
    url = "https://api.meetup.com/2/rsvps?&sign=true&photo-host=public&event_id=#{event_ids.join(',')}&page=200&key=#@api_key"
    rsvps = []

    get_paged url do |res|
      rsvps += res['results'].map { |r| [r['event']['id'], Attendee.new(r['member']['member_id'], r['member']['name'])] }
    end

    Hash[rsvps.group_by {|e,_| e }.map {|e,rs| [e, rs.map {|f| f[1]}]}]
  end
end
