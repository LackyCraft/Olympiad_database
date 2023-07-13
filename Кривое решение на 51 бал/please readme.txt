pg_dump не умеет дампить роли и пользователей (.

По этому роли можно проверить на серваке (ну и все задание тоже):
ip: 
user: super_admins
password: 
database: transport 

Основная бд лежит в схеме public
Дополнительная схема, для оператора - views (в ней находятся представления)

(В случае, если бэкап восстанавливать не лень)
Или после востановления бэкапа выполнить (это создаст такие же роли, как у меня):

		CREATE ROLE "admin" WITH 
			NOSUPERUSER
			NOCREATEDB
			NOCREATEROLE
			INHERIT
			NOLOGIN
			NOREPLICATION
			NOBYPASSRLS
			CONNECTION LIMIT -1;

		-- DROP ROLE admins2;

		CREATE ROLE admins2 WITH 
			NOSUPERUSER
			NOCREATEDB
			NOCREATEROLE
			INHERIT
			LOGIN
			NOREPLICATION
			NOBYPASSRLS
			CONNECTION LIMIT -1;

		-- DROP ROLE client;

		CREATE ROLE client WITH 
			NOSUPERUSER
			NOCREATEDB
			NOCREATEROLE
			INHERIT
			LOGIN
			NOREPLICATION
			NOBYPASSRLS
			CONNECTION LIMIT -1;

		-- DROP ROLE super_admins;

		CREATE ROLE super_admins WITH 
			SUPERUSER
			NOCREATEDB
			NOCREATEROLE
			INHERIT
			LOGIN
			NOREPLICATION
			NOBYPASSRLS
			CONNECTION LIMIT -1;

	--добавить оператора
	create user client WITH  password '123456' 
	IN role operator;
	
	-- добавить админа
	create user admins2 password '123456';
	GRANT admin TO admins2 WITH ADMIN OPTION
	
	-- добавить супер админа
	CREATE USER super_admins WITH SUPERUSER PASSWORD '123456';