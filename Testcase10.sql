/*
MÔ TẢ TÌNH HUỐNG PHANTOM THÊM 1 ĐƠN VỊ DỮ LIỆU KHI ĐỌC 2 LẦN
GIAO TÁC THỨ NHẤT LÀ UPDATE ĐỌC 2 LẦN ĐỂ XEM XEM VIỆC UPDATE CÓ THÀNH CÔNG HAY KHÔNG
NHƯNG VIỆC ĐỌC 2 LẦN ĐÓ LẠI SINH RA MỘT DỮ LIỆU MỚI.
TỨC LÀ VIỆC ĐỌC LẦN THỨ 2 MONG MUỐN CHỈ ĐỂ XEM VIỆC UPDATE CÓ THÀNH CÔNG HAY KHÔNG
NHƯNG LẠI XUẤT HIỆN MỘT DỮ LIỆU MỚI PHÙ HỢP VỚI VIỆC ĐỌC.
TRƯỜNG HỢP PHANTOM DO CÓ THÊM 1 DÒNG DỮ LIỆU CHỈ ĐƯỢC GIẢI QUYẾT KHI TA CÀI ĐẶT Ở
MỨC CÔ LẬP THỨ 4.

*/
--T1
ALTER proc update_UudaiKH (@magiamgia int,@maKH nvarchar(10),@tenmagg nvarchar(40),@tiengiam money)
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM UuDaiKHTV WHERE maKHTV=@maKH
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
		WAITFOR DELAY N'00:00:05'
		update UuDaiKHTV set tenmaGiamGiaKH=@tenmagg, sotiengiamTV=@tiengiam where maKHTV=@maKH and maGiamGiaKH=@magiamgia
		SELECT * FROM UuDaiKHTV WHERE maKHTV=@maKH
	End try
	Begin catch
		rollback transaction
	End catch

Commit transaction
go
EXEC update_UudaiKH 1,N'KH001',N'KHUYẾN MÃI TẾT',100.00000
--T2
ALTER proc them_UudaiKH (@magiamgia int,@maKH nvarchar(10),@tenmagg nvarchar(40),@tiengiam money)
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM UuDaiKHTV WHERE maKHTV=@maKH
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
		insert into UuDaiKHTV 
		values (@magiamgia,@maKH,@tenmagg,@tiengiam)
		SELECT * FROM UuDaiKHTV WHERE maKHTV=@maKH
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
EXEC them_UudaiKH 2,N'KH001',N'KHUYẾN MÃI',100.00000
---GIẢI QUYẾT VẤN ĐỀ
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
