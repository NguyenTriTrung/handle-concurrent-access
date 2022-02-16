/*

TÌNH HUỐNG VỀ VẤN ĐỀ DEADLOCK :
-MÔ TẢ TÌNH HUỐNG:
MỘT GIAO TÁC ĐANG THỰC HIỆN VIỆC THÊM 1 MENU_CHINHANH VÀ VIỆC ĐỌC 2 LẦN,GIỮ KHÓA ĐỌC ĐẾN CUỐI GIAO TÁC,GIAO TÁC 2
CŨNG ĐỌC 2 LẦN VÀ GIỮ KHÓA ĐẾN CUỐI GIAO TÁC.
GIAO TÁC 1 MUỐN THỰC HIỆN VIỆC INSERT TRÊN 1 ĐƠN VỊ DỮ LIỆU THÌ PHẢI ĐỢI GIAO TÁC 2 THỰC HIỆN VIỆC COMMIT THAO TÁC ĐỌC MỚI ĐƯỢC
INSERT,NHƯNG GIAO TÁC 2 CŨNG UPDATE MENU_CHINHANH VÀ PHẢI ĐỢI GIAO TÁC 1 COMMIT,DẪN ĐẾN VIỆC 2 GIAO TÁC ĐỢI NHAU VÀ DẪN ĐẾN DEADLOCK,
VÀ HỆ THỐNG TỰ ĐỘNG HỦY 1 GIAO TÁC ĐỂ GIAO TÁC KIA THỰC HIỆN TIẾP CÔNG VIỆC CỦA MÌNH(TUÂN THEO WAIT-DIE)
--> PHƯƠNG PHÁP GIẢI QUYẾT LÀ CHO THAO TÁC ĐỌC NHẢ RA NGAY MÀ KHÔNG PHẢI ĐỢI ĐẾN CUỐI NHƯNG VẤN ĐỀ SẼ BỊ LỖI TRANH CHÂP ĐỒNG THỜI
UNREPEATABLE READ.

*/
--T1
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

exec them_Menu NA1,'23-10',13


--T2
alter proc update_Menu (@maCN nvarchar(3), @ghichumenu nvarchar(200), @mamenu int)
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		select * from Menu WITH(HOLDLOCK,ROWLOCK) WHERE maChiNhanh=@maCN
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

EXEC update_Menu NA1,N'25-10',5

SELECT * FROM Menu
-----------GIẢI QUYẾT VẤN ĐỀ
--CÓ THỂ HẠN CHẾ CÁC GIAO TÁC THỰC HIỆN VỚI CÙNG 1 ĐƠN VỊ DỮ LIỆU
--HẠN CHẾ MỨC CÔ LẬP(MỨC CÔ LẬP CÀNG CAO THÌ XỬ LÝ ĐỒNG THỜI CÀNG KÉM)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED 
--BỎ ĐI NHỮNG CÀI ĐẶT TRÊN THAO TÁC