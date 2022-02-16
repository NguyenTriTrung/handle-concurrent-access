/*

TÌNH HUỐNG VỀ VẤN ĐỀ DEADLOCK :
-MÔ TẢ TÌNH HUỐNG:
MỘT GIAO TÁC ĐANG THỰC HIỆN VIỆC THÊM 1 ƯU ĐÃI KHÁCH HÀNG VÀ VIỆC ĐỌC 2 LẦN,GIỮ KHÓA ĐỌC ĐẾN CUỐI GIAO TÁC,GIAO TÁC 2
CŨNG ĐỌC 2 LẦN VÀ GIỮ KHÓA ĐẾN CUỐI GIAO TÁC.
GIAO TÁC 1 MUỐN THỰC HIỆN VIỆC INSERT TRÊN 1 ĐƠN VỊ DỮ LIỆU THÌ PHẢI ĐỢI GIAO TÁC 2 THỰC HIỆN VIỆC COMMIT THAO TÁC ĐỌC MỚI ĐƯỢC
INSERT,NHƯNG GIAO TÁC 2 CŨNG UPDATE ƯU ĐÃI KHÁCH HÀNG VÀ PHẢI ĐỢI GIAO TÁC 1 COMMIT,DẪN ĐẾN VIỆC 2 GIAO TÁC ĐỢI NHAU VÀ DẪN ĐẾN DEADLOCK,
VÀ HỆ THỐNG TỰ ĐỘNG HỦY 1 GIAO TÁC ĐỂ GIAO TÁC KIA THỰC HIỆN TIẾP CÔNG VIỆC CỦA MÌNH
--> PHƯƠNG PHÁP GIẢI QUYẾT LÀ CHO THAO TÁC ĐỌC NHẢ RA NGAY MÀ KHÔNG PHẢI ĐỢI ĐẾN CUỐI NHƯNG VẤN ĐỀ SẼ BỊ LỖI TRANH CHÂP ĐỒNG THỜI
UNREPEATABLE READ.
*/
--T1
ALTER proc them_UudaiKH (@magiamgia int,@maKH nvarchar(10),@tenmagg nvarchar(40),@tiengiam money)
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM UuDaiKHTV(HOLDLOCK) WHERE maKHTV=@maKH
		if( @maKH is null or @magiamgia is null or @tenmagg is null or @tiengiam is null)
		begin 
			print(N'Thông tin không được rỗng')
			rollback transaction
			return
		end
		--Kiểm tra mã khách hàng có tồn tại
		if(not exists (select * from KhachHangThanhVien where maKH=@maKH))
		begin 
			print(N'Mã khách hàng không tồn tại')
			rollback transaction
			return
		end
		-- Kiểm tra ưu đãi có tồn tại
		if(exists (select * from UuDaiKHTV where maKHTV=@maKH and maGiamGiaKH=@magiamgia))
		begin 
			print(N'Mã ưu đãi đã tồn tại')
			rollback transaction
			return
		end
		--thêm
		WAITFOR DELAY N'00:00:05'
		insert into UuDaiKHTV 
		values (@magiamgia,@maKH,@tenmagg,@tiengiam)
		SELECT * FROM UuDaiKHTV WHERE maKHTV=@maKH
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go 
EXEC them_UudaiKH 13,N'KH001',N'KHUYẾN MÃI 20/10',100.00000

-------------------------------------
--T2
ALTER proc update_UudaiKH (@magiamgia int,@maKH nvarchar(10),@tenmagg nvarchar(40),@tiengiam money)
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM UuDaiKHTV(HOLDLOCK) WHERE maKHTV=@maKH
		if( @maKH is null or @magiamgia is null or @tenmagg is null or @tiengiam is null)
		begin 
			print(N'Thông tin không được rỗng')
			rollback transaction
			return
		end
		--Kiểm tra mã khách hàng có tồn tại
		if(not exists (select * from KhachHangThanhVien where maKH=@maKH))
		begin 
			print(N'Mã khách hàng không tồn tại')
			rollback transaction
			return
		end
		-- Kiểm tra ưu đãi có tồn tại
		if(not exists (select * from UuDaiKHTV where maKHTV=@maKH and maGiamGiaKH=@magiamgia))
		begin 
			print(N'Mã ưu đãi không tồn tại')
			rollback transaction
			return
		end
		-- Kiểm tra thông tin trùng lắp
		if(exists (select * from UuDaiKHTV where maKHTV=@maKH and maGiamGiaKH=@magiamgia and tenmaGiamGiaKH=@tenmagg and sotiengiamTV=@tiengiam))
		begin 
			print(N'Thông tin bị trùng lắp')
			rollback transaction
			return
		end
		--sửa
		update UuDaiKHTV set tenmaGiamGiaKH=@tenmagg, sotiengiamTV=@tiengiam where maKHTV=@maKH and maGiamGiaKH=@magiamgia
		SELECT * FROM UuDaiKHTV WHERE maKHTV=@maKH
	End try
	Begin catch
		rollback transaction
	End catch

Commit transaction
go
EXEC update_UudaiKH 4,N'KH001',N'KHUYẾN MÃI DỊP 14/02 CHO CÁC CẶP',50.000

-----------GIẢI QUYẾT VẤN ĐỀ
--CÓ THỂ HẠN CHẾ CÁC GIAO TÁC THỰC HIỆN VỚI CÙNG 1 ĐƠN VỊ DỮ LIỆU
--HẠN CHẾ MỨC CÔ LẬP(MỨC CÔ LẬP CÀNG CAO THÌ XỬ LÝ ĐỒNG THỜI CÀNG KÉM)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED 
--BỎ ĐI NHỮNG CÀI ĐẶT TRÊN THAO TÁC