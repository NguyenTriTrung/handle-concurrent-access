/*
MÔ TẢ TÌNH HUỐNG:
-CÓ MỘT GIAO TÁC THỰC HIỆN VIỆC XÓA MÓN VÀ UPDATE LẠI SỐ LƯỢNG,NHƯNG BỊ DELAY TRƯỚC KHI
UPDATE VÀ CÓ MỘT GIAO TÁC(T2) ĐỌC TABLE LOAI(MỨC CÔ LẬP SỐ 1) VÀ THẤY DỮ LIỆU LÚC NÀY CHƯA ĐƯỢC UPDATE NHƯNG RÕ RÀNG LÀ 
MÓN ĐÃ BỊ XÓA.LỖI NÀY LÀ DIRTY READ.
GIẢI QUYẾT LÀ NÂNG MỨC CÔ LẬP LÊN SỐ 2
*/
--T1
alter proc Xoa_mon(@mamon nvarchar(10))
as
Begin transaction
	Begin try
		--Kiểm tra món có tồn tại
		select * from Mon where maMon=@mamon
		if (not exists( select * from Mon where maMon=@mamon))
		begin
			print(N'Mã món không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra món có tồn tại trong menu
		if (exists (select * from ChiTietMenu where maMon=@mamon))
		begin
			print(N'Không được phép xóa')
			rollback transaction
			return
		end
		--Kiểm tra món đã được đặt 
	declare @maloaibandau nvarchar(10)
	set @maloaibandau=(select MALOAI from Mon where maMon=@mamon)
	delete from Mon where maMon=@mamon
	update LOAI SET TONGSOMON=TONGSOMON-1 WHERE MALOAI=@maloaibandau
	select * from Mon where maMon=@mamon
	End try
	Begin catch
		rollback transaction
	End catch
	--xóa và cập nhật lại số lượng của loại

Commit transaction
go
---T2
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
CREATE PROC CHITIETLOAI
AS
BEGIN
	SELECT * FROM LOAI join Mon on LOAI.MALOAI=Mon.MALOAI
END
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
EXEC CHITIETLOAI

----GIẢI QUYẾT LÀ NÂNG MỨC CÔ LẬP LÊN SỐ 2