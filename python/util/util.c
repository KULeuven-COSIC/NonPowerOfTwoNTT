#define PY_SSIZE_T_CLEAN
#include <Python.h>
#include <stdint.h>
#include <math.h>

static uint64_t fast_exp(uint64_t b, uint64_t e, uint64_t m) {
    uint64_t r = 1;
    b = b % m;
    if (1 & e) {
        r = b;
    }
    while (e) {
        e >>= 1;
        b = (b * b) % m;
        if (e & 1) {
            r = (r * b) % m;
        }
    }
    return r;
}

static PyObject *util_principal_root_of_unity(PyObject *self, PyObject *args) {
    uint64_t n;
    uint64_t m;
    if (!PyArg_ParseTuple(args, "KK", &n, &m)) {
        return NULL;
    }
    for (uint64_t x = 2; x < m; x++) {
        uint64_t r = fast_exp(x, (m - 1) / n, m);

        for (uint64_t i = n / 2; i > 1; i--) {
            if (n % i == 0) {
                if (fast_exp(r, i, m) == 1) {
                    goto not_principal_root;
                }
            }
        }
        return PyLong_FromUnsignedLongLong(r);

        not_principal_root:
        ;
    }
    Py_INCREF(Py_None);
    return Py_None;
}

static PyObject *util_fast_exp(PyObject *self, PyObject *args) {
    uint64_t b;
    uint64_t e;
    uint64_t m;
    if (!PyArg_ParseTuple(args, "KKK", &b, &e, &m)) {
        return NULL;
    }
    uint64_t r = fast_exp(b, e, m);
    return PyLong_FromUnsignedLongLong(r);
}

static PyObject *util_orthogonal_idempotents(PyObject *self, PyObject *args) {
    uint64_t n;
    PyObject *factor_list;
    if (!PyArg_ParseTuple(args, "O!K", &PyList_Type, &factor_list, &n)) {
        return NULL;
    }
    int count = (int) PyList_Size(factor_list);
    uint64_t *f = (uint64_t *) calloc(count, sizeof(uint64_t));
    for (int i = 0; i < count; i++) {
        f[i] = PyLong_AsUnsignedLongLong(PyList_GetItem(factor_list, i));
    }
    PyObject* idempotents = PyList_New(count);
    for (uint64_t i = 2; i < n; i++) {
        if (i*i % n == i) {
            for (int j = 0; j < count; j++) {
                if ((f[j] * i) % n == 0) {
                    PyList_SetItem(idempotents, j, PyLong_FromUnsignedLongLong(i));
                }
            }
        }
    }
    free(f);
    return idempotents;
}

static PyObject *util_NTT(PyObject *self, PyObject *args) {
    uint64_t p_root;
    uint64_t m;
    PyObject *x_list;
    if (!PyArg_ParseTuple(args, "O!KK", &PyList_Type, &x_list, &p_root, &m)) {
        return NULL;
    }
    int N = (int) PyList_Size(x_list);
    uint64_t *x = (uint64_t *) calloc(N, sizeof(uint64_t));
    for (int i = 0; i < N; i++) {
        x[i] = PyLong_AsUnsignedLongLong(PyList_GetItem(x_list, i));
    }

    uint64_t *X = (uint64_t *) calloc(N, sizeof(uint64_t));
    if (N < 64) {
    uint64_t wk = 1;
	uint64_t wnk = 1;
	for (int k = 0; k < N; k++) {
		wnk = 1;
        for (int n = 0; n < N; n++) {
            X[k] += (x[n] * wnk) % m;
            X[k] %= m;
			wnk = (wnk * wk) % m;
		}
		wk = (wk * p_root) % m;
	}
	} else {
	int k;
    #pragma omp parallel for
    for (k = 0; k < N; k++) {
		uint64_t wnk = 1;
		uint64_t wk = fast_exp(p_root, k, m);
        for (int n = 0; n < N; n++) {
            X[k] += (x[n] * wnk) % m;
            X[k] %= m;
			wnk = (wnk * wk) % m;
		}
		X[k] %= m;
	}
	}

    PyObject* X_list = PyList_New(N);
    for (int i = 0; i < N; i++) {
         PyList_SetItem(X_list, i, PyLong_FromUnsignedLongLong(X[i]));
    }
    free(x);
    free(X);
    return X_list;
}


static PyMethodDef UtilMethods[] = {
    {"principal_root_of_unity",  util_principal_root_of_unity, METH_VARARGS, "Return a principal root of unity for n-point NTT with modulus m."},
    {"fast_exp",  util_fast_exp, METH_VARARGS, "Returns b raised to the power e (mod m)."},
    {"orthogonal_idempotents",  util_orthogonal_idempotents, METH_VARARGS, "Return central orthogonal idempotents for list of coprime factors of n."},
    {"ntt",  util_NTT, METH_VARARGS, "Return NTT of list with given primitive root and modulus."},
    {NULL, NULL, 0, NULL}        /* Sentinel */
};

static struct PyModuleDef utilmodule = {
    PyModuleDef_HEAD_INIT,
    "init",
    NULL,
    -1,
    UtilMethods
};

PyMODINIT_FUNC PyInit_util(void) {
    return PyModule_Create(&utilmodule);
}