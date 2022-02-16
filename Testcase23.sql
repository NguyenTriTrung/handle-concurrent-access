/*
MÔ TẢ TÌNH HUỐNG:
-CÓ MỘT GIAO TÁC THỰC HIỆN VIỆC THÊM MÓN VÀ UPDATE LẠI SỐ LƯỢNG,NHƯNG BỊ DELAY TRƯỚC KHI
UPDATE VÀ CÓ MỘT GIAO TÁC(T2) ĐỌC TABLE LOAI(MỨC CÔ LẬP SỐ 1) VÀ THẤY DỮ LIỆU LÚC NÀY CHƯA ĐƯỢC UPDATE NHƯNG RÕ RÀNG LÀ 
MÓN ĐÃ ĐƯỢC THÊM.LỖI NÀY LÀ DIRTY READ.
-GIẢI QUYẾT BẰNG CÁCH NÂNG MỨC CÔ LẬP LÊN 2
*/

--T1
ALTER proc Them_Mon (@mamon nvarchar(10),@tenmon nvarchar(40),@maloai nvarchar(3),@gia money,@gioithieu nvarchar(200))
as
Begin transaction
	Begin try
		--kiểm tra thông tin không được rỗng
		SELECT * FROM Mon 
		if ( @mamon is null or @tenmon is null or  @maloai is null or @gia is null or @gioithieu is null)
		begin
			print(N'Thông tin không được rỗng')
			rollback transaction
			return
		end
		--kiểm tra mã món có tồn tại
		if (exists (select * from Mon where maMon=@mamon))
		begin
			print(N'Mã món không tồn tại')
			rollback transaction
			return
		end
		--kiểm tra mã loại có tồn tại
		if (not exists (select * from Loai where maLoai=@maloai))
		begin
			print(N'Mã loại không tồn tại')
			rollback transaction
			return
		end
			insert into Mon
			values (@mamon,@tenmon,@maloai,@gia,@gioithieu)
			declare @tongsomon int
			set @tongsomon=(SELECT TONGSOMON FROM Loai where maLoai=@maloai)
			--Tăng số lượng món ở loại
			WAITFOR DELAY N'00:00:05'
			update Loai set tongsomon = @tongsomon + 1 where maLoai=@maloai
			SELECT * FROM Mon 
	End try
	Begin catch
		rollback transaction
	End catch
	--Thêm
Commit transaction
go

EXEC Them_Mon ANVAT012,N'BÁNH MÌ QUE',N00,15.00,N'không có'

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