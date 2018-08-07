/****************************************************************************

Git <https://github.com/sniper00/MoonNetLua>
E-Mail <hanyongtao@live.com>
Copyright (c) 2015-2017 moon
Licensed under the MIT License <http://opensource.org/licenses/MIT>.

****************************************************************************/
#include "config.h"
#include "common/concurrent_map.hpp"
#include "common/rwlock.hpp"
#include "common/log.hpp"

namespace asio {
	class io_service;
}

namespace moon
{
	using env_t = concurrent_map<std::string, std::string, rwlock>;
	using unique_service_db_t = concurrent_map<std::string, uint32_t, rwlock>;

	class worker;

	class router
	{
	public:
		friend class server;

		using register_func = service_ptr_t(*)();

		router(std::vector<worker*>& workers, log* logger);

		router(const router&) = delete;

		router& operator=(const router&) = delete;

		size_t servicenum() const;

		size_t workernum() const;

		uint32_t new_service(const std::string& service_type, bool unique, bool shareth, int workerid, const string_view_t& config);

		void remove_service(uint32_t serviceid, uint32_t sender, uint32_t respid, bool crashed = false);

		void runcmd(uint32_t sender, const std::string& cmd, int32_t responseid);

		void send_message(const message_ptr_t& msg) const;

		void send(uint32_t sender, uint32_t receiver, const buffer_ptr_t& buf, const string_view_t& header, int32_t responseid, uint8_t mtype) const;

		void broadcast(uint32_t sender, const message_ptr_t& msg);

		bool register_service(const std::string& type, register_func func);

		std::shared_ptr<std::string> get_env(const std::string& name) const;

		void set_env(const string_view_t& name, const string_view_t& value);

		uint32_t get_unique_service(const string_view_t& name) const;

		void set_unique_service(const string_view_t& name, uint32_t v);

		log* logger() const;

		void make_response(uint32_t sender, const string_view_t&, const string_view_t& content, int32_t resp, uint8_t mtype = PTYPE_TEXT) const;
	
		void on_service_remove(uint32_t serviceid);

		asio::io_service& get_io_service(uint32_t serviceid);

		void set_stop(std::function<void()> f);

		void stop_server();
	private:
		bool workerid_valid(uint8_t);

		worker* next_worker();
	
		bool has_serviceid(uint32_t serviceid) const;

		bool try_add_serviceid(uint32_t serviceid);
	private:
		std::atomic<uint32_t> next_workerid_;
		std::vector<worker*>& workers_;
		std::unordered_map<std::string, register_func > regservices_;
		mutable rwlock serviceids_lck_;
		std::unordered_set<uint32_t> serviceids_;
		env_t env_;
		unique_service_db_t unique_services_;
		log* logger_;
		std::function<void()> stop_;
	};
}