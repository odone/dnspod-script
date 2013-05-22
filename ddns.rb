#encoding: utf-8
require 'net/http'
require 'net/https'
require 'json'

# 配置参数
$username = 'odone@qq.com'  # 用户名（登陆邮箱）
$password = 'password'      # 密码 （你懂得）
$sub_domains = ['www', '@'] # 使用域名

def get_wan_ip
	socket = TCPSocket.new 'ns1.dnspod.net', 6666
	return socket.gets(16)
end

# 扩展String类
class String
	def call(data)
		uri = URI(self)
		
		http = Net::HTTP.new uri.host, uri.port
		http.use_ssl = true if uri.scheme == 'https'

		unless (defined? data.format) then
			data['format'] = 'json'
		end
		
	    req = Net::HTTP::Post.new(uri.path)
    	req.set_form_data(data)
		
	    res = http.start do |http|
			http.request(req)
		end
		
		result = JSON.parse res.body
		
		if (result['status']['code'].eql? '1') then
			return result
		else
			puts result['status']['message']
			exit
		end
	end
end

'https://dnsapi.cn/Domain.List'.call(
	'login_email' 		=> $username, 
	'login_password' 	=> $password,
)['domains'].each do |domain|
	if domain['name'].eql? 'cciwe.com' then
		
		records = 'https://dnsapi.cn/Record.List'.call(
			'login_email' 		=> $username, 
			'login_password' 	=> $password,
			'domain_id'			=> domain['id']
		)['records']
		
		# 循环记录
		if $sub_domains.include? record['name'] then
			records.each do |record|
				if record['type'].eql? 'A' then
					ip = get_wan_ip.to_s
					$sub_domains.each do |sub_domain|
						unless domain['value'].eql? ip then
							result = 'https://dnsapi.cn/Record.Modify'.call(
								'login_email'	 	=> $username,
								'login_password' 	=> $password,
								'domain_id'			=> domain['id'].to_s,
								'record_id'			=> record['id'].to_s,
								'sub_domain'		=> record['name'],
								'value'				=> ip,
								'record_type'		=> 'A',
								'record_line'		=> '默认',
								'format' 			=> 'json'
							)
							if result['status']['code'].eql? '1' then
						  puts "#{record['name']}.#{domain['name']}  更新dns成功"
							else
						  puts "#{record['name']}.#{domain['name']}  更新dns失败"
						end
						end
					end
				end
			end
		# 不存在，新增记录
		else
			result = 'https://dnsapi.cn/Record.Create'.call(
				'login_email'	 	=> $username,
				'login_password' 	=> $password,
				'domain_id'			=> domain['id'].to_s,
				'sub_domain'		=> record['name'],
				'value'				=> ip,
				'record_type'		=> 'A',
				'record_line'		=> '默认',
				'format' 			=> 'json'
			)
		end
		
		break
	end
end