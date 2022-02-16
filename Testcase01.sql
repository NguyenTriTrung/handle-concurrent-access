/*giải quyết tranh chấp đồng thời về lostupdate
với 2 store proc là T1: Update_Loai và T2: Update_Loai
Mô tả tình huống:
+khi update một loại đã tồn tại thì việc kiểm tra xem loại đó có tồn tại chưa của 2 giao tác 
trên cùng một đơn vị dữ liệu điều được vì ở mức cô lập mặc định của SQL server
nên SL sẽ được nhả ra ngay(SL với SL thì tương thích).
+và giao tác này update @tenloai và commit xong ,giao tác kia cũng update 
tên loại (ở đây chưa đọc được tên loại đã bị update T1 mà chỉ đọc tên loại trước lúc update của T1)
và dẫn đến việc lostupdate
-->xử lý là ta sẽ đẩy lên mức cô lập thứ 3 nhưng sẽ xảy ra deadlock vì ở đây GIAO TÁC T1,T2 điều
giữ SL đến cuối,nếu có giao tác XL thì sẽ phải chờ và 2 giao tác chờ nhau.
-Ta đã cài đặt mã nguồn nên chỉ cần thực thi câu lệnh exec Update_Loai và đã giả sử
tình huống xảy ra.
*/
--T1
--MÃ NGUỒN T1,T2
ALTER proc Update_Loai (@maloai nvarchar(3), @tenloai nvarchar(40))
as
Begin transaction
	Begin try
		--kiểm tra thông tin không được rỗng
			SELECT * FROM Loai--giả sử muốn xem dữ liệu trước khi thay đổi
		if ( @maloai is null or @tenloai is null)
		begin
			print(N'Thông tin không được rỗng')
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
		--kiểm tra thông tin trùng khớp
		if (exists (select * from Loai where maLoai=@maloai and tenloai=@tenloai))
		begin
			print(N'Thông tin trùng khớp')
			rollback transaction
			return
		end
	End try
	Begin catch
		rollback transaction
	End catch
	--Update
	WAITFOR DELAY '00:00:10'
	update Loai set tenloai=@tenloai where maLoai=@maloai--khóa xl
	SELECT * FROM Loai--dòng này để cho thấy việc thêm dữu liệu ở giao tác 1
Commit transaction
go
--T1
EXEC Update_Loai 'N01','a'
/*tức là ở đây việc giao tác 1 khi kết thúc chỉ có thể đọc dữ liệu của nó cập nhật mà không đọc đucợ dữ liệu đã được giao tác 2
cập nhật nên kết quả cuối cùng là giao tác 2.*/
--T2
EXEC Update_Loai 'N01','b'
SELECT * FROM Loai
--GIẢI QUYẾT VẤN ĐỀ LOSTUPDATE
--MÃ NGUỒN T1,T2
ALTER proc Update_Loai (@maloai nvarchar(3), @tenloai nvarchar(40))
as
Begin transaction
	Begin try
		--kiểm tra thông tin không được rỗng
			SELECT * FROM Loai with (holdlock,rowlock)--giả sử muốn xem dữ liệu trước khi thay đổi
		if ( @maloai is null or @tenloai is null)
		begin
			print(N'Thông tin không được rỗng')
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
		--kiểm tra thông tin trùng khớp
		if (exists (select * from Loai where maLoai=@maloai and tenloai=@tenloai))
		begin
			print(N'Thông tin trùng khớp')
			rollback transaction
			return
		end
	End try
	Begin catch
		rollback transaction
	End catch
	--Update
	WAITFOR DELAY '00:00:10'
	update Loai set tenloai=@tenloai where maLoai=@maloai--khóa xl
	SELECT * FROM Loai--dòng này để cho thấy việc thêm dữu liệu ở giao tác 1
Commit transaction
go