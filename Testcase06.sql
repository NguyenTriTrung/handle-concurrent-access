/*
XỬ LÝ VỀ VẤN ĐỀ PHANTOM:
-MÔ TẢ TÌNH HUỐNG:
+ VỚI MỘT GIAO TÁC ĐANG THỰC HIÊN VIỆC UPDATE MENU NHƯNG VÀ XEM VIỆC UPDATE CÓ ĐƯỢC HOÀN THÀNH KHÔNG
NHƯNG CHẲNG MAY CÓ MỘT  GIAO TÁC CŨNG ĐANG INSERT TRÊN ĐƠN VỊ DỮ LIỆU ĐÓ LÀM CHO VIỆC XEM COI UPDATE
CỦA GIAO TÁC BAN ĐẦU THÊM 1 DÒNG DỮ LIỆU KHÔNG RÕ NGUYÊN NHÂN
+ VỚI VẤN ĐỀ NÀY TA CHỈ CÓ THỂ LÀ CÀI Ở MỨC CÔ LẬP SERIALIZABLE ĐỂ CÓ KEY RANGE LOCK,MỨC CÔ LẬP THỨ 
3 CHƯA GIẢI QUYẾT ĐƯỢC HẾT VÌ PHATOM CÓ 2 DẠNG LÀ THÊM VÀ MẤT ĐI MỘT DỮ LIỆU.
NÊN TA CẦN XÉT XEM LÀ TÌNH HUỐNG ĐANG DIỄN RA ĐỂ TRÁNH VIỆC CHẬM TRỄ TRÊN HỆ THỐNG KHI NÂNG MỨC CÔ LẬP
*/
--T1
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
		waitfor delay N'00:00:05'
		update Menu set GhiChuMenu=@ghichumenu where maChiNhanh=@maCN and maMenu=@mamenu
		select * from Menu WHERE maChiNhanh=@maCN
	End try
	Begin catch
		rollback transaction
	End catch

Commit transaction
go

EXEC update_Menu NA1,N'23-02',1

SELECT * FROM Menu

--T2
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
		insert into Menu 
		values (@maCN,@ghichumenu,@mamenu)
		select * from Menu WHERE maChiNhanh=@maCN
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go

exec them_Menu NA1,'23-10',6

-----------------------GIẢI QUYẾT VẤN ĐỀ 

--T1
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
alter proc update_Menu (@maCN nvarchar(3), @ghichumenu nvarchar(200), @mamenu int)
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		select * from Menu  WHERE maChiNhanh=@maCN
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
		waitfor delay N'00:00:05'
		update Menu set GhiChuMenu=@ghichumenu where maChiNhanh=@maCN and maMenu=@mamenu
		select * from Menu WHERE maChiNhanh=@maCN
	End try
	Begin catch
		rollback transaction
	End catch

Commit transaction
go

EXEC update_Menu NA1,N'23-02',1

SELECT * FROM Menu

--T2
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
		insert into Menu 
		values (@maCN,@ghichumenu,@mamenu)
		select * from Menu WHERE maChiNhanh=@maCN
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go