 /*
XỬ LÝ VỀ VẤN ĐỀ UNREPEATABLE READ :
-MÔ TẢ TÌNH HUỐNG:
MỘT GIAO TÁC INSERT MENU VÀO VÀ ĐỌC 2 LẦN ĐỂ KIẾM TRA XEM VIỆC INSERT ĐÓ CÓ THÀNH CÔNG
HAY KHÔNG.
VIỆC INSERT THÀNH CÔNG NHƯNG CÓ MỘT GIAO TÁC THỰC HIỆN VIỆC THAY ĐỔI TRÊN ĐƠN VỊ DỮ LIỆU
ĐÓ(UPDATE) VÀ LÀM CHO NGƯỜI THỰC HIỆN GIAO TÁC 1 MUỐN ĐỌC ĐƠN VỊ DỮ LIỆU CŨ KHÔNG ĐƯỢC.
HƯỚNG GIẢI QUYẾT : TA CÓ THỂ GIỮ GIAO TÁC ĐỌC TỪ ĐẦU ĐẾN KHI COMMIT ĐỂ
TRÁNH CÓ GIAO TÁC KHÔNG THÊM GIỮA 2 LẦN ĐỌC CỦA GIAO TÁC 1.
*/
--T1
ALTER proc them_Menu (@maCN nvarchar(3), @ghichumenu nvarchar(200), @mamenu int)
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		select * from Menu WHERE maChiNhanh=@maCN 
		if (@maCN is null or @ghichumenu is null or @mamenu is null)
		begin
			print(N'Thông tin không được rỗng')
			rollback transaction
			return
		end
		--Kiểm tra mã chi nhánh có tồn tại
		if (not exists (select * from ChiNhanh where maChiNhanh=@maCN))
		begin
			print(N'Mã chi nhánh không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra menu đã tồn tại
		if (exists (select * from Menu where maChiNhanh=@maCN and maMenu=@mamenu))
		begin
			print(N'Menu đã tồn tại')
			rollback transaction
			return
		end
		--thêm
		waitfor delay N'00:00:05'
		insert into Menu 
		values (@maCN,@ghichumenu,@mamenu)
		select * from Menu WHERE maChiNhanh=@maCN
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go

exec them_Menu NA1,'23-10',12
--T2
alter proc update_Menu (@maCN nvarchar(3), @ghichumenu nvarchar(200), @mamenu int)
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		select * from Menu WHERE maChiNhanh=@maCN
		if (@maCN is null or @ghichumenu is null or @mamenu is null)
		begin
			print(N'Thông tin không được rỗng')
			rollback transaction
			return
		end
		--Kiểm tra mã chi nhánh có tồn tại
		if (not exists (select * from ChiNhanh where maChiNhanh=@maCN))
		begin
			print(N'Mã chi nhánh không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra menu đã tồn tại
		if (not exists (select * from Menu where maChiNhanh=@maCN and maMenu=@mamenu))
		begin
			print(N'Menu không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra thông tin không được trùng khớp
		if ( exists (select * from Menu where maChiNhanh=@maCN and GhiChuMenu=@ghichumenu and maMenu=@mamenu))
		begin
			print(N'Thông tin bị trùng khớp')
			rollback transaction
			return
		end
		--thêm
		update Menu set GhiChuMenu=@ghichumenu where maChiNhanh=@maCN and maMenu=@mamenu
		select * from Menu WHERE maChiNhanh=@maCN
	End try
	Begin catch
		rollback transaction
	End catch

Commit transaction
go

EXEC update_Menu NA1,N'25-10',1

SELECT * FROM Menu

-----GIẢI QUYẾT VẤN ĐỀ
--1: NÂNG LÊN MỨC CÔ LẬP SỐ 3 HAY LÀ CÀI ĐẶT HOLDLOCK,ROWLOCK
ALTER proc them_Menu (@maCN nvarchar(3), @ghichumenu nvarchar(200), @mamenu int)
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		select * from Menu WITH (HOLDLOCK,ROWLOCK) WHERE maChiNhanh=@maCN 
		if (@maCN is null or @ghichumenu is null or @mamenu is null)
		begin
			print(N'Thông tin không được rỗng')
			rollback transaction
			return
		end
		--Kiểm tra mã chi nhánh có tồn tại
		if (not exists (select * from ChiNhanh where maChiNhanh=@maCN))
		begin
			print(N'Mã chi nhánh không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra menu đã tồn tại
		if (exists (select * from Menu where maChiNhanh=@maCN and maMenu=@mamenu))
		begin
			print(N'Menu đã tồn tại')
			rollback transaction
			return
		end
		--thêm
		waitfor delay N'00:00:05'
		insert into Menu 
		values (@maCN,@ghichumenu,@mamenu)
		select * from Menu WHERE maChiNhanh=@maCN
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go