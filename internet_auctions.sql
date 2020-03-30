if OBJECT_ID('statistic') is not null
if OBJECT_ID('finalized_auctions') is not null drop table finalized_auctions
if OBJECT_ID('auctions_history') is not null drop table auctions_history
if OBJECT_ID('auctions') is not null drop table auctions
if OBJECT_ID('admins') is not null drop table admins
if OBJECT_ID('users') is not null drop table users
if OBJECT_ID('login_details') is not null drop table login_details
if OBJECT_ID('contacts') is not null drop table contacts
if OBJECT_ID('productions_details') is not null drop table productions_details
if OBJECT_ID('products') is not null drop table products
if OBJECT_ID('categories') is not null drop table categories

go
if OBJECT_ID('login_details') is not null drop table login_details
go
create table login_details(
	login nvarchar(20) primary key,
	password nvarchar(20),
)

go
if OBJECT_ID('categories') is not null drop table categories
go
create table categories(
	category_id int primary key identity(1,1),
	category_name nvarchar(20),
	category_description nvarchar(100)
)

go
if OBJECT_ID('products') is not null drop table products
go
create table products(
	product_id int primary key identity(1,1),
	category_id int,
	product_name nvarchar(20),
	used bit,
	production_id int
	foreign key (category_id) references categories(category_id) 
)

go
if OBJECT_ID('productions_details') is not null drop table productions_details
go
create table productions_details(
	production_id int primary key identity(1,1),
	town nvarchar(20),
	street nvarchar(20),
	street_number int,
	date_production date
)

go
if OBJECT_ID('contacts') is not null drop table contacts
go
create table contacts(
	contact_id int primary key identity(1,1),
	email nvarchar(20),
	phone_number int,
)

go
if OBJECT_ID('users') is not null drop table users
go
create table users(
	user_id int primary key identity(1,1),
	join_date date,
	contact_id int unique,
	login nvarchar(20) unique,
	status bit,
	foreign key (contact_id) references contacts(contact_id),
	foreign key (login) references login_details(login) 
)

go
if OBJECT_ID('auctions') is not null drop table auctions
go
create table auctions(
	auction_id int primary key identity(1,1),
	product_id int unique,
	user_seller_id int,
	date_start date,
	date_end date,
	bids int,
	foreign key (user_seller_id) references users(user_id), 
	foreign key (product_id) references products(product_id) 

)

go
if OBJECT_ID('finalized_auctions') is not null drop table finalized_auctions
go
create table finalized_auctions(
	auction_id int primary key,
	user_buyer_id int,
	amount int
)

go
if OBJECT_ID('auctions_history') is not null drop table auctions_history
go
create table auctions_history(
	auction_history_id int primary key identity(1,1),
	user_buyer_id int,
	bid_date date,
	bid_amount int,
	auction_id int
	foreign key (auction_id) references auctions(auction_id) 
)

go
if OBJECT_ID('admins') is not null drop table admins
go
create table admins(
	admin_id int primary key identity(1,1),
	join_date date,
	login nvarchar(20) unique,
	contact_id int,
	foreign key (contact_id) references contacts(contact_id),
	foreign key (login) references login_details(login)
)
go
if OBJECT_ID('statistic') is not null
drop table statistic
go
create table statistic(
	acounts_amount int,
	online_acounts int,
	finalized_auctions_amount int
)



--procedura dodania uzytkownika
go
if OBJECT_ID('add_user') is not null
drop procedure add_user;
go
CREATE PROCEDURE add_user
(
@login nvarchar(20),
@password nvarchar(20),
@email nvarchar(20),
@phone_number int
)
AS
insert into contacts (email,phone_number) values
(@email,@phone_number)
insert into login_details(login,password) values
(@login,@password)
insert into users (join_date,contact_id,login) values
(GETDATE(),(select contact_id from contacts
 where email=@email and phone_number=@phone_number),
 (select login from login_details
 where login=@login)); 
 
 -- dodawanie kategorii
 go
 if OBJECT_ID('add_category') is not null
 drop procedure add_category
 go
 create procedure add_category
 (
 @category_name nvarchar(20),
 @category_description nvarchar(100)
 )
 as
 begin  
 insert into categories (category_name,category_description) values
 (@category_name,@category_description)
 end
 -- dodawanie szczegolow produkcji
 go
 if OBJECT_ID('add_productions_details') is not null
 drop procedure add_productions_details
 go
 create procedure add_productions_details
 (
 @town nvarchar(20),
 @street nvarchar(20),
 @street_number int,
 @date_production date
 )
 as 
 insert into productions_details (town,street,street_number,date_production) values
 (@town,@street,@street_number,@date_production);

 -- dodawanie produktu
 go
 if OBJECT_ID('add_product_with_details') is not null
 drop procedure add_product_with_details
 go
 create procedure add_product_with_details
 (
 @category_id int,
 @product_name nvarchar(20),
 @used bit,
 @production_id int,
 @town nvarchar(20),
 @street nvarchar(20),
 @street_number int,
 @date_production date
 )
 as exec add_productions_details @town,@street,@street_number,@date_production
 insert into products (category_id,product_name,used,production_id) values
 (@category_id,@product_name,@used,@production_id);
 
 -- dodawanie licytacji
 go
 if OBJECT_ID('add_auction') is not null
 drop proc add_auction
 go
 create procedure add_auction
 (
 @user_id int,
 @end_date date,
 @category_id int,
 @product_name nvarchar(20),
 @used bit,
 @production_id int,
 @town nvarchar(20),
 @street nvarchar(20),
 @street_number int,
 @date_production date

 )
 as exec add_product_with_details @category_id,@product_name,@used,@production_id,@town,@street,@street_number,@date_production
 insert into auctions (user_seller_id,date_start,date_end,product_id) values
 (@user_id,getdate(),@end_date,(select max(product_id) from products));

 -- licytacja
 go
 IF OBJECT_ID('bid') is NOT NULL --je¿eli funkcja istnieje
     DROP FUNCTION bid; --kasowanie
 go
 create function bid
 (@zmienna int, @id int) returns int
 as
 begin
 declare @maks as int
 set @maks = (select max(bid_amount) from auctions_history A
 join auctions B on A.auction_id=B.auction_id
 where B.auction_id=@id)
 if @maks>=@zmienna
 return 0;
 else
 return 1;
 return 2;
 end

 go
 if OBJECT_ID('bidding') is not null
 drop proc bidding
 go
 create proc bidding 
 (
 @user_id int,
 @auction_id int,
 @amount int
 )
 as 
 begin 
 if dbo.bid(@amount,@auction_id)=1
 insert into auctions_history(user_buyer_id,bid_date,bid_amount,auction_id) values
 (@user_id,GETDATE(),@amount,@auction_id);
 else
 print N'nie';
 end

 -- procedura finalizowania aukcji
go
if OBJECT_ID('finalization') is not null
drop proc finalization;
go
create proc finalization
as
begin
declare iterator cursor 
for select date_end,auction_id from auctions
for read only
declare @date date
declare @id int
open iterator
fetch iterator into @date,@id
while @@fetch_status=0
begin
 if (select amount from finalized_auctions where @id=auction_id) is null
 begin 
 if @date<GETDATE()
 insert into finalized_auctions(auction_id,user_buyer_id,amount) values
 (@id,(select user_buyer_id from auctions_history 
 where auction_id=@id and bid_amount=(select max(bid_amount) from auctions_history where @id=auction_id)),
 (select bid_amount from auctions_history 
 where auction_id=@id and bid_amount=(select max(bid_amount) from auctions_history where @id=auction_id)))
 end
 fetch iterator into @date,@id
end
close iterator;
DEALLOCATE iterator;
end


go
if OBJECT_ID('login_proc') is not null
drop proc login_proc;
go
create proc login_proc
(
	@login Nvarchar(20),
	@password Nvarchar(20)
)
as
begin
if (select user_id from users
	join login_details on login_details.login=users.login
	where login_details.login=@login and password=@password) is not null
 begin
 declare @user int
 set @user = (select user_id from users
	join login_details on login_details.login=users.login
	where login_details.login=@login and password=@password)
	update users
	set status=1
	where user_id=@user
 end
end
 
go
if OBJECT_ID('logout_proc') is not null
drop proc logout_proc;
go
create proc logout_proc
(
	@login Nvarchar(20),
	@password Nvarchar(20)
)
as
begin
if (select user_id from users
	join login_details on login_details.login=users.login
	where login_details.login=@login and password=@password) is not null
 begin
 declare @user int
 set @user = (select user_id from users
	join login_details on login_details.login=users.login
	where login_details.login=@login and password=@password)
	update users
	set status=0
	where user_id=@user
 end
end
 
 -- triggery
 go
 if OBJECT_ID('online_acounts') is not null
 drop trigger online_acounts
 go
 create trigger online_acounts
 on users
 after update
 as
 begin
 declare @id int
 set @id = (select user_id from inserted) 
 if (select status from users where @id=user_id)=1
 update statistic
 set online_acounts=online_acounts+1
 else
 update statistic
 set online_acounts=online_acounts-1
 end
 
 go
 if OBJECT_ID('bids_counter') is not null
 drop trigger bids_counter
 go
 create trigger bids_counter
 on auctions_history
 after insert
 as
 begin
 declare @value int
 declare @id int
 set @id = (select B.auction_id from auctions B
 join inserted A on  B.auction_id=A.auction_id) 
 print @id;
 set @value = (select bids from auctions B
 join inserted A on  B.auction_id=A.auction_id)
 if @value is null
 set @value=1;
 else
 set @value=@value+1;
 update auctions
 set bids=@value
 where auction_id=@id;
 end

 go
 if OBJECT_ID('users_counter') is not null
 drop trigger users_counter
 go
 create trigger users_counter
 on users
 after insert
 as
 begin
 declare @amount int
 update statistic
 set acounts_amount=acounts_amount+1;
 end

  go
  if OBJECT_ID('admin_counter') is not null
 drop trigger admin_counter
 go
 create trigger admin_counter
 on admins
 after insert
 as
 begin
 declare @amount int
 update statistic
 set acounts_amount=acounts_amount+1;
 end

 go
 if OBJECT_ID('finalized_auctions_counter') is not null
 drop trigger finalized_auctions_counter
 go
 create trigger finalized_auctions_counter
 on finalized_auctions
 after insert
 as
 begin
 declare @amount int
 update statistic
 set finalized_auctions_amount=finalized_auctions_amount+1;
 end



 /*
 insert into statistic values (0,0,0)
 exec add_user "litla_dira00","xxx","cia@misikisi",318
 exec add_user "litl_dir00","asd018","cia@misi",31201
 exec add_user "ab","x","cia@misi",111
 exec add_category "samochod","pozwala na szybkie przemieszczanie sie po swiecie"
 exec add_auction 2,'2021-02-03',1,"audi a4",1,1,"krakow","kalwaryjska",30,'2012-02-11'
 exec add_auction 1,'2020-02-09',1,"audi a4",1,1,"krakow","kalwaryjska",30,'2012-02-11'
 exec add_auction 3,'2020-02-09',1,"kia stinger",0,4,"krakow","norymberska",20,'2013-02-22'
 exec add_productions_details "krakow","sliska",14,'2012-02-27'
 exec add_product_with_details 1,"kia stinger",1,1,"krakow","sliska",15,'2012-02-27'
 exec add_product_with_details 1,"fiat 126p",0,2,"krakow","sliska",14,'2012-02-27'
 exec bidding 1,2,100
 exec bidding 2,2,200
 exec bidding 3,1,510
 exec finalization

 select * from categories
 select * from products
 select  *from productions_details
 select * from users
 select * from contacts
 select * from login_details
 select * from auctions
 select * from auctions_history
 select * from statistic
 select * from auctions A
 left join finalized_auctions B on A.auction_id=B.auction_id 
 */

 --widoki
 go
 if OBJECT_ID('all_users') is not null
 drop view all_users;
 go
 create view all_users as
 select login,email,phone_number from users as a
 join contacts as b on a.contact_id=b.contact_id
	
 --select * from all_users

 go
 if OBJECT_ID('auctions_today') is not null
 drop view auctions_today;
 go
 create view auctions_today as
 select product_name,login,date_start,date_end,bids from auctions
 join products on products.product_id=auctions.product_id
 join users on users.user_id=auctions.user_seller_id 
 where date_end=(select convert(varchar,getdate(),23))

 --select * from auctions_today
 
 go
 if OBJECT_ID('all_finalized_auctions') is not null
 drop view all_finalized_auctions;
 go
 create view all_finalized_auctions as
 select user_seller_id,user_buyer_id,bids,amount,date_end,product_name from auctions A
 left join finalized_auctions B on A.auction_id=B.auction_id
 join products on products.product_id=A.product_id
 where amount is not null
 
 --select * from all_finalized_auctions

 go
 if OBJECT_ID('all_not_finalized_auctions') is not null
 drop view all_not_finalized_auctions;
 go
 create view all_not_finalized_auctions as
 select login,bids,date_start,date_end,product_name from auctions A
 left join finalized_auctions B on A.auction_id=B.auction_id
 join products on products.product_id=A.product_id
 join users on users.user_id=A.user_seller_id
 where amount is null

 --select * from all_not_finalized_auctions

 go
 if OBJECT_ID('all_auctions') is not null
 drop view all_auctions;
 go
 create view all_auctions as
 select product_name,login,date_start,date_end,bids from auctions
 join products on products.product_id=auctions.product_id
 join users on users.user_id=auctions.user_seller_id 

 --select * from all_auctions

 go
 if OBJECT_ID('all_categories') is not null
 drop view all_categories;
 go
 create view all_categories as
 select category_name,category_description from categories

 --select * from all_categories

 go
 if OBJECT_ID('online_acounts_amount') is not null
 drop view online_acounts_amount;
 go
 create view online_acounts_amount as
 select login,user_id from users
 where status=1

 --select * from online_acounts_amount

 go
 if OBJECT_ID('all_products') is not null
 drop view all_products;
 go
 create view all_products as
 select product_name,used from products
 --select * from all_products

 go
 if OBJECT_ID('all_products_with_details') is not null
 drop view all_products_with_details;
 go
 create view all_products_with_details as
 select product_name,used,category_name,date_production from products
 join categories on categories.category_id=products.category_id
 join productions_details on productions_details.production_id=products.production_id
 --select * from all_products_with_details
/*
delete from users
delete from contacts
delete from login_details
delete from categories
delete from products
delete from productions_details
delete from auctions_history
delete from auctions
delete from admins
delete from finalized_auctions
delete from statistic
*/

--backup database test to disk = 'C:\backups\test.bak';
--restore database test from disk= 'C:\backups\test.bak';