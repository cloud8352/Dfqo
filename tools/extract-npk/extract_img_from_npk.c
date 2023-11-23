/**
 * 《DNF（地下城与勇士）》NPK打包文件解包器
 *
 * 作者：向阳叶（QQ：914286415）
 * 版本：0.2
 * 最后修订日期：2022-7-15
 *
 * 说明：
 * 	适用于ImagePacks2文件夹中的img文件包，以及SoundPacks文件夹中的ogg文件包。
 * 	文件名中的'/'会被替换为'_'，即不生成子文件夹。
 *
 * 警告：仅供个人学习与研究使用，切勿用于非法用途！
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

typedef struct FileInfo{
	uint32_t offset;
	uint32_t size;
	char name[0x100];
}FileInfo;
#define SIZEOF_FILENAME (sizeof (((FileInfo *)0)->name))

static const int8_t npkMagicStr[0x10] = "NeoplePack_Bill";
static const char fileNameKey[SIZEOF_FILENAME] =
	"puchikon@neople dungeon and fighter "
	"DNFDNFDNFDNFDNFDNFDNFDNFDNFDNFDNF"
	"DNFDNFDNFDNFDNFDNFDNFDNFDNFDNFDNF"
	"DNFDNFDNFDNFDNFDNFDNFDNFDNFDNFDNF"
	"DNFDNFDNFDNFDNFDNFDNFDNFDNFDNFDNF"
	"DNFDNFDNFDNFDNFDNFDNFDNFDNFDNFDNF"
	"DNFDNFDNFDNFDNFDNFDNFDNFDNFDNFDNF"
	"DNFDNFDNFDNFDNFDNFDNF"
;

int main(const int argc, const char * const * const argv){
	if (argc < 2){
		printf("Usage : %s <npkFilename>\n", argv[0]);
		goto EXCEPTION;
	}

	FILE * pNpk = fopen(argv[1], "rb");
	if (NULL == pNpk){
		fprintf(stderr, "ERROR : Failed to open npk file \"%s\".\n", argv[1]);
		goto EXCEPTION;
	}

	{
		int8_t buf[sizeof npkMagicStr];
		if ( fread(buf, sizeof (int8_t), sizeof npkMagicStr, pNpk) != sizeof npkMagicStr ){
			fprintf(stderr, "ERROR : Failed to load npk magic string.\n");
			goto EXCEPTION_NPK_OPENED;
		}

		if ( memcmp(buf, npkMagicStr, sizeof npkMagicStr) != 0 ){
			fprintf(stderr, "ERROR : Failed to check npk magic string.\n");
			goto EXCEPTION_NPK_OPENED;
		}
	}

	const uint32_t fileAmount;
	if ( fread( (void *)&fileAmount, sizeof (uint32_t), 1, pNpk ) != 1 ){
		fprintf(stderr, "ERROR : Failed to load file amount.\n");
		goto EXCEPTION_NPK_OPENED;
	}

	if (!( fileAmount > 0 )){
		fprintf(stderr, "ERROR : The amount of file(s) in npk is 0.\n");
		goto EXCEPTION_NPK_OPENED;
	}

	FileInfo * pFileInfo = (FileInfo *)malloc(sizeof (FileInfo) * fileAmount);
	if (NULL == pFileInfo){
		fprintf(stderr, "ERROR : Failed to allocate memory for FileInfo array.\n");
		goto EXCEPTION_NPK_OPENED;
	}

	if ( fread(pFileInfo, sizeof (FileInfo), fileAmount, pNpk) != fileAmount ){
		fprintf(stderr, "ERROR : Failed to load FileInfo.\n");
		goto EXCEPTION_FILEINFO_MALLOCED;
	}

	uint32_t maxFileSize = 0;
	for (uint32_t i = 0; i < fileAmount; i += 1){
		if ( pFileInfo[i].size > maxFileSize ){
			maxFileSize = pFileInfo[i].size;
		}

		if ( pFileInfo[i].name[SIZEOF_FILENAME - 1] != '\0' ){
			fprintf(stderr, "ERROR : The length of file name is greater than max.\n");
			goto EXCEPTION_FILEINFO_MALLOCED;
		}
		for (uint8_t j = 0; j < (SIZEOF_FILENAME - 1); j += 1){
			pFileInfo[i].name[j] ^= fileNameKey[j];
			if ( '/' == pFileInfo[i].name[j] ){
				pFileInfo[i].name[j] = '_';
			}
		}
		if ( '\0' == pFileInfo[i].name[0] ){
			fprintf(stderr, "ERROR : The file name in npk is empty.\n");
			goto EXCEPTION_FILEINFO_MALLOCED;
		}
	}

	if (!( maxFileSize > 0 )){
		fprintf(stderr, "ERROR : All the files in the npk are empty.\n");
		goto EXCEPTION_FILEINFO_MALLOCED;
	}

	uint8_t * pFileBuf = (uint8_t *)malloc(maxFileSize);
	if (NULL == pFileBuf){
		fprintf(stderr, "ERROR : Failed to allocate memory for file buffer.\n");
		goto EXCEPTION_FILEINFO_MALLOCED;
	}

	for (uint32_t i = 0; i < fileAmount; i += 1){
		fseek(pNpk, pFileInfo[i].offset, SEEK_SET);
		if ( fread(pFileBuf, sizeof (uint8_t), pFileInfo[i].size, pNpk) != pFileInfo[i].size ){
			fprintf(stderr, "ERROR : Failed to load file from npk.\n");
			goto EXCEPTION_FILEBUF_MALLOCED;
		}

		FILE * pWriteFile = fopen(pFileInfo[i].name, "wb");
		if (NULL == pWriteFile){
			fprintf(stderr, "ERROR : Failed to open file to be written.\n");
			goto EXCEPTION_FILEBUF_MALLOCED;
		}

		if ( fwrite(pFileBuf, sizeof (uint8_t), pFileInfo[i].size, pWriteFile) != pFileInfo[i].size ){
			fprintf(stderr, "ERROR : Failed to write file.\n");

			fclose(pWriteFile);
			pWriteFile = NULL;

			goto EXCEPTION_FILEBUF_MALLOCED;
		}

		fclose(pWriteFile);
		pWriteFile = NULL;
	}

	free(pFileBuf);
	pFileBuf = NULL;

	free(pFileInfo);
	pFileInfo = NULL;

	fclose(pNpk);
	pNpk = NULL;

	puts("Success!");

	return 0;

//exception part
	abort();
EXCEPTION_FILEBUF_MALLOCED:
	free(pFileBuf);
	pFileBuf = NULL;
EXCEPTION_FILEINFO_MALLOCED:
	free(pFileInfo);
	pFileInfo = NULL;
EXCEPTION_NPK_OPENED:
	fclose(pNpk);
	pNpk = NULL;
EXCEPTION:
	return 1;
}
