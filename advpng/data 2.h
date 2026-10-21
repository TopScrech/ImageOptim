#ifndef __DATA_H
#define __DATA_H

unsigned char* data_dup(const unsigned char* Adata, unsigned Asize);
unsigned char* data_alloc(unsigned size);
void data_free(unsigned char* data);

class data_ptr {
	unsigned char* data;
	bool own;
public:
	data_ptr() : data(0), own(false) { }

	data_ptr(data_ptr& A)
	{
		data = A.data;
		own = A.own;
		A.own = false;
	}

	data_ptr(unsigned char* Adata, bool Aown = true) : data(Adata), own(Aown) { }

	~data_ptr() { if (own) data_free(data); }

	void operator=(data_ptr& A)
	{
		if (own) data_free(data);
		data = A.data;
		own = A.own;
		A.own = false;
	}

	void operator=(unsigned char* Adata)
	{
		if (own) data_free(data);
		data = Adata;
		own = true;
	}

	operator unsigned char*() { return data; }
};

#endif
