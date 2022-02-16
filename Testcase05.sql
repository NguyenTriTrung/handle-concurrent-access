/* Ở ĐÂY TA CÓ TRƯỜNG HỢP LOSTUPDATE VIỆC SỬA 1 CHI NHÁNH
-GIẢ SỬ TA CÓ TÌNH HUỐNG LÀ 1 CHỦ HAY 1 NGƯỜI NÀO ĐÓ MUỐN UPDATE
1 CHI NHÁNH NHƯNG CÙNG LÚC ĐÓ CÓ 1 NGƯỜI KHÁC CŨNG UPDATE THÌ
SẼ XẢY RA TÌNH HUỐNG LÀ CÙNG UPDATE TRÊN 1 ĐƠN VỊ DỮ LIỆU VÀ 
2 NGƯỜI THÌ KHÔNG THẤY ĐƯỢC KẾT QUẢ UPDATE CỦA NHAU VÀ DẪN ĐẾN VIỆC 
GIAO TÁC NÀY LÀM MẤT DỮ LIỆU CỦA GIAO TÁC KIA.
--> TA SẼ DÙNG HOLDLOCK VÀ ROWLOCK ĐỂ NGĂN NGỪA VIỆC NÀY NHƯNG VIỆC NÀY SẼ DẪN ĐẾN
DEADLOCK VÀ CHỈ 1 GIAO TÁC ĐƯỢC THỰC HIỆN TIẾP.
UPDATE Ở ĐÂY CÓ THỂ LÀ SDT,TÊN,..
*/

ALTER proc update_ChiNhanh(@maCN nvarchar(3),@tenCN nvarchar(40),@quan nvarchar(15), @phuong nvarchar(15), @diachichitiet nvarchar(50),@DTCN nvarchar(12),@nvql nvarchar(10))
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM ChiNhanh
		if (@maCN is null or @tenCN is null or @diachichitiet is null or @DTCN is null OR @quan is null or @phuong is null )--or @nvql is null
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
		--Kiểm tra thông tin có trùng khớp
		if (exists (select * from ChiNhanh where maChiNhanh=@maCN and tenChiNhanh=@tenCN and Quan=@quan and Phuong=@phuong and DiaChiChiTiet=@diachichitiet and DienThoaiChiNhanh=@DTCN and maNguoiQLChiNhanh =@nvql ))
		begin
			print(N'Thông tin trùng khớp')
			rollback transaction
			return
		end
	End try
	Begin catch
		rollback transaction
	End catch
	--update
	waitfor delay N'00:00:05'
	update ChiNhanh set tenChiNhanh=@tenCN, Quan=@quan, Phuong=@phuong, DienThoaiChiNhanh=@DTCN, maNguoiQLChiNhanh=@nvql where maChiNhanh=@maCN
	SELECT * FROM ChiNhanh
Commit transaction
go

--T1
EXEC update_ChiNhanh NA1,N'THE COFFEE HOUSE',5,2,02,0123432232,NULL
SELECT * FROM ChiNhanh

--T2
EXEC update_ChiNhanh NA1,COFFEE,6,2,02,0123432232,NULL
--GIẢI QUYẾT
ALTER proc update_ChiNhanh(@maCN nvarchar(3),@tenCN nvarchar(40),@quan nvarchar(15), @phuong nvarchar(15), @diachichitiet nvarchar(50),@DTCN nvarchar(12),@nvql nvarchar(10))
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM ChiNhanh WITH(HOLDLOCK,ROWLOCK)
		if (@maCN is null or @tenCN is null or @diachichitiet is null or @DTCN is null OR @quan is null or @phuong is null )--or @nvql is null
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
		--Kiểm tra thông tin có trùng khớp
		if (exists (select * from ChiNhanh where maChiNhanh=@maCN and tenChiNhanh=@tenCN and Quan=@quan and Phuong=@phuong and DiaChiChiTiet=@diachichitiet and DienThoaiChiNhanh=@DTCN and maNguoiQLChiNhanh =@nvql ))
		begin
			print(N'Thông tin trùng khớp')
			rollback transaction
			return
		end
	End try
	Begin catch
		rollback transaction
	End catch
	--update
	waitfor delay N'00:00:05'
	update ChiNhanh set tenChiNhanh=@tenCN, Quan=@quan, Phuong=@phuong, DienThoaiChiNhanh=@DTCN, maNguoiQLChiNhanh=@nvql where maChiNhanh=@maCN
	SELECT * FROM ChiNhanh
Commit transaction
go