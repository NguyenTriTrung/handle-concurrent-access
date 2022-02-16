/*
XỬ LÝ VỀ VẤN ĐỀ UNREPEATABLE READ :
-MÔ TẢ TÌNH HUỐNG:
MỘT GIAO TÁC INSERT ƯU ĐÃI KHÁCH HÀNG THÀNH VIÊN VÀO VÀ ĐỌC 2 LẦN ĐỂ KIẾM TRA XEM VIỆC INSERT ĐÓ CÓ THÀNH CÔNG
HAY KHÔNG.
VIỆC INSERT THÀNH CÔNG NHƯNG CÓ MỘT GIAO TÁC THỰC HIỆN VIỆC THAY ĐỔI TRÊN ĐƠN VỊ DỮ LIỆU
ĐÓ(UPDATE) VÀ LÀM CHO NGƯỜI THỰC HIỆN GIAO TÁC 1 MUỐN ĐỌC ĐƠN VỊ DỮ LIỆU CŨ KHÔNG ĐƯỢC(ĐƠN VỊ DỮ LIỆU CŨ LÚC NÀY ĐÃ UPDATE).
HƯỚNG GIẢI QUYẾT : TA CÓ THỂ GIỮ GIAO TÁC ĐỌC TỪ ĐẦU ĐẾN KHI COMMIT ĐỂ
TRÁNH CÓ GIAO TÁC KHÔNG THÊM GIỮA 2 LẦN ĐỌC CỦA GIAO TÁC 1.
*/
--T1
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
EXEC them_UudaiKH 11,N'KH001',N'KHUYẾN MÃI 20/10',100.00000

-------------------------------------
--T2
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
		update UuDaiKHTV set tenmaGiamGiaKH=@tenmagg, sotiengiamTV=@tiengiam where maKHTV=@maKH and maGiamGiaKH=@magiamgia
		SELECT * FROM UuDaiKHTV WHERE maKHTV=@maKH
	End try
	Begin catch
		rollback transaction
	End catch

Commit transaction
go
EXEC update_UudaiKH 1,N'KH001',N'KHUYẾN MÃI DỊP 14/02 CHO CÁC CẶP',50.000

----GIẢI QUYẾT VẤN ĐỀ
--DÙNG MỨC CÔ LẬP THỨ 3
--TỰ CÀI ĐẶT TRÊN THAO TÁC CỦA GIAO TÁC
ALTER proc them_UudaiKH (@magiamgia int,@maKH nvarchar(10),@tenmagg nvarchar(40),@tiengiam money)
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM UuDaiKHTV WITH (HOLDLOCK,ROWLOCK) WHERE maKHTV=@maKH
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