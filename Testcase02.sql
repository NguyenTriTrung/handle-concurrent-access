/*
XỬ LÝ VẤN ĐỀ LOSTUPDATE:
MÔ TẢ TÌNH HUỐNG:
KHI MỘT GIAO TÁC THỰC HIỆN VIỆC CẬP NHÂT ƯU ĐÃI KHÁCH HÀNG VÀ CHƯA GHI NHẬN LẠI THÌ MỘT 
GIAO TÁC KHÁC THỰC HIỆN VIỆC CẬP NHẬT ƯU ĐÃI KHÁCH HÀNG VÀ GHI ĐÈ LÊN CÁI CẬP NHẬT CỦA
GIAO TÁC 1 DẪN ĐẾN VIỆC KHI CÓ AI ĐÓ MUỐN XEM CẬP NHẬT CỦA GIAO TÁC 1 SẼ KHÔNG ĐƯỢC
VÌ LÚC NÀY GIAO TÁC 2 ĐÃ GHI ĐÈ LÊN GIAO TÁC 1.
CÓ THỂ XỬ LÝ VẤN ĐỀ NÀY BẰNG VIỆC GIỮ CHO GIAO TÁC ĐỌC ĐẾN CUỐI COMMIT MỚI NHẢ RA
NHƯNG VIỆC NÀY SẼ DẪN ĐẾN VẤN ĐỀ LOSTUPDATE.

*/

ALTER proc update_UudaiKH (@magiamgia int,@maKH nvarchar(10),@tenmagg nvarchar(40),@tiengiam money)
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM UuDaiKHTV  WHERE maKHTV=@maKH
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
--T1
EXEC update_UudaiKH 1,N'KH001',N'KHUYẾN MÃI ',100.00000

--T2
EXEC update_UudaiKH 1,N'KH001',N'KHUYẾN MÃI DỊP 14/02 CHO CÁC CẶP',100.00000
--GIẢI QUYẾT
ALTER proc update_UudaiKH (@magiamgia int,@maKH nvarchar(10),@tenmagg nvarchar(40),@tiengiam money)
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM UuDaiKHTV WITH(HOLDLOCK,ROWLOCK)  WHERE maKHTV=@maKH
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