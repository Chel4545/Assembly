
int main() {
	int a;

	__asm 
	{
		mov eax, 1
		add eax, 3
		mov a, eax
	}
}
