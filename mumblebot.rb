#!/usr/local/bin/ruby -Ku
# coding: UTF-8

require 'rubygems'
require 'time'
require 'rubytter'

TwitterID = 'TwitterID'
TwitterPW = 'TwitterPW'
MurmurLogPath = '/etc/murmur/murmur.log'

LoginKey  = :login
LogoutKey = :logout
LogRe = %r!<W>(.{23}) 1 => <\d+:(.+?)\(-?\d+\)> (Auth|Conn)!
Limit = Time.now - 60



# murmur log

log = nil
open(MurmurLogPath) do |fp|
	fp.seek(-2048,IO::SEEK_END)
	log = fp.read
end

inout = {}
[LoginKey,LogoutKey].each{|i| inout[i]=[] }

log.to_a.each do |i|
	if LogRe === i then
		tstr, nstr, cstr = $1, $2, $3
		next  unless Limit <= Time.parse(tstr)
		name = nstr.gsub(/\A(.{3})(.*)/){$1 + '*' * $2.size}
		inout[LoginKey]  << name  if cstr == 'Auth'
		inout[LogoutKey] << name  if cstr == 'Conn'
	end
end
m0 = inout[LoginKey].sort.uniq.join(' ')
m1 = inout[LogoutKey].sort.uniq.join(' ')
msgary = []
msgary << %Q!login: #{m0}!   if 0 < m0.size
msgary << %Q!logout: #{m1}!  if 0 < m1.size

msg = msgary.join(' / ')



# twitter update

if 0 < msg.size then
	rt = Rubytter.new(TwitterID, TwitterPW)
	rt.update msg
end


# twitter delete

if (Time.now.min % 10) == 5 then
	rt = Rubytter.new(TwitterID, TwitterPW)
	tnow = Time.now - (60 * 60 * 24)
	stat = rt.user_timeline(TwitterID, :count => 190)
	stat.shift
	stat.each do |i|
		next  if tnow < Time.parse(i.created_at)
		p i.id
		sleep 2
		begin
			rt.remove_status i.id
		rescue Rubytter::APIError
		end
	end
end
